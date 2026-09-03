import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class FidelityScreen extends StatefulWidget {
  const FidelityScreen({super.key});

  @override
  State<FidelityScreen> createState() => _FidelityScreenState();
}

class _FidelityScreenState extends State<FidelityScreen> {
  String? _scannedCardId;
  int _currentPizzas = 0;
  int _targetPizzas = 9;
  String _customerName = "";
  String? _errorMessage;
  bool _showProgress = false;

  bool _isLoading = true;
  bool _isScanning = false;
  bool _isProcessingScan = false;

  static const String _parentDocId = "7TFknuq2ZcgFvO9czyq8gtQSELH2";

  static const Color _pinkPrimary = Color(0xFFE65086);
  static const Color _pinkDark = Color(0xFFC2185B);
  static const Color _pinkLight = Color(0xFFF48FB1);
  static const Color _pinkAccent = Color(0xFFFFC1D6);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _cardSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _parentSubscription;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    _startParentListener();
    _checkIfCardExists();
  }

  @override
  void dispose() {
    _cardSubscription?.cancel();
    _parentSubscription?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkIfCardExists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedId = prefs.getString('casita_card_id');

    if (savedId != null) {
      debugPrint("💾 [Local] ID trouvé en mémoire : $savedId");
      setState(() {
        _scannedCardId = savedId;
        _isScanning = false;
        _isLoading = true;
      });
      _setupFirebaseListener(savedId);
    } else {
      debugPrint("ℹ️ [Local] Aucune carte enregistrée.");
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });
    }
  }

  void _startParentListener() {
    _parentSubscription?.cancel();

    debugPrint("🔎 [PARENT] Démarrage écoute parent : users/$_parentDocId");

    _parentSubscription = FirebaseFirestore.instance
        .doc("users/$_parentDocId")
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        debugPrint("📥 [PARENT] exists=${snapshot.exists}");
        debugPrint("📦 [PARENT] data=${snapshot.data()}");

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final goal = (data['goal'] as num?)?.toInt() ?? 9;

          setState(() {
            _targetPizzas = goal;
          });

          debugPrint("🎯 [PARENT] goal chargé = $_targetPizzas");
        } else {
          debugPrint("⚠️ [PARENT] Document parent introuvable ou vide");
          setState(() {
            _targetPizzas = 9;
          });
        }
      },
      onError: (error) {
        debugPrint("💥 [PARENT] Erreur écoute : $error");
        if (!mounted) return;

        setState(() {
          _targetPizzas = 9;
        });
      },
    );
  }

  void _setupFirebaseListener(String cardId) {
    if (!mounted) return;

    debugPrint("🔄 [Firestore] Tentative de connexion pour la carte : $cardId");

    final t = AppLocalizations.of(context)!;

    _cardSubscription?.cancel();

    setState(() {
      _currentPizzas = 0;
      _customerName = "...";
      _errorMessage = null;
      _isLoading = true;
    });

    _cardSubscription = FirebaseFirestore.instance
        .doc("users/$_parentDocId/customers/$cardId")
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        debugPrint(
          "🟢 [Firestore] Réponse Firebase reçue ! Existe : ${snapshot.exists}",
        );

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          debugPrint("📊 [Firestore] Données trouvées : $data");

          setState(() {
            _errorMessage = null;
            _currentPizzas = (data['count'] as num?)?.toInt() ?? 0;
            _customerName = (data['name'] as String?) ?? t.defaultCustomer;
            // Par défaut absent/faux : le client ne voit QUE son QR code
            // tant que le gérant n'a pas activé ce Switch depuis la Maître.
            _showProgress = (data['showProgress'] as bool?) ?? false;
            _isScanning = false;
            _isLoading = false;
          });
        } else {
          debugPrint(
            "⚠️ [Firestore] Document introuvable pour la carte : $cardId",
          );
          setState(() {
            _errorMessage = t.cardNotFound;
            _currentPizzas = 0;
            _customerName = t.customerNotFound;
            _isScanning = false;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        debugPrint("💥 [Firestore] Erreur écoute : $error");

        String message = t.networkError;
        if (error is FirebaseException) {
          if (error.code == 'permission-denied') {
            message = t.accessDenied;
          } else if (error.code == 'unavailable') {
            message = t.networkError;
          } else {
            message = t.syncError;
          }
        }

        setState(() {
          _errorMessage = message;
          _isLoading = false;
          _isScanning = false;
        });
      },
    );
  }

  Future<void> _saveCardId(String rawId) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    try {
      String cleanId = rawId;

      if (rawId.startsWith("PIZZA:")) {
        cleanId = rawId.replaceAll("PIZZA:", "");
      }

      if (cleanId.contains('.client_')) {
        final parts = cleanId.split('.client_');
        cleanId = parts[1];
        debugPrint("🧹 [Wallet] ID extrait et nettoyé : $cleanId");
      }

      setState(() {
        _isScanning = false;
        _isLoading = true;
        _scannedCardId = cleanId;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('casita_card_id', cleanId);

      await _scannerController.stop();
      _setupFirebaseListener(cleanId);
    } catch (e) {
      debugPrint("💥 [SaveCard] Erreur : $e");
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.scanError;
          _isLoading = false;
          _isScanning = false;
        });
      }
    } finally {
      _isProcessingScan = false;
    }
  }

  Future<void> _unlinkCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('casita_card_id');
    await _cardSubscription?.cancel();
    _cardSubscription = null;

    setState(() {
      _scannedCardId = null;
      _currentPizzas = 0;
      _customerName = "";
      _errorMessage = null;
      _isScanning = false;
      _isLoading = false;
    });
  }

  void _retry() {
    if (_scannedCardId == null) return;
    _setupFirebaseListener(_scannedCardId!);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    double progress = _targetPizzas == 0 ? 0 : _currentPizzas / _targetPizzas;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3F6),
      appBar: AppBar(
        title: Text(
          t.myLoyalty,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _pinkPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_scannedCardId != null && !_isScanning && !_isLoading)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: t.unlinkCardTooltip,
              onPressed: _unlinkCard,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _pinkPrimary),
            )
          : _isScanning
              ? _buildScannerWidget(t)
              : _scannedCardId == null
                  ? _buildNoCardWidget(t)
                  : _buildWalletCardWidget(progress, t),
    );
  }

  Widget _buildNoCardWidget(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: _pinkPrimary),
          const SizedBox(height: 24),
          Text(
            t.activateCardTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            t.activateCardSubtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isScanning = true;
                _isLoading = false;
              });
            },
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(
              t.scanQrButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pinkPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showManualEntryDialog(t),
            icon: const Icon(Icons.keyboard, color: _pinkPrimary),
            label: Text(
              t.enterCodeManually,
              style: const TextStyle(color: _pinkPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Alternative au scan : le gérant peut envoyer l'identifiant (ex :
  /// "PIZZA:0000000000000000") par WhatsApp, et le client le colle ici
  /// au lieu de devoir scanner en personne à la pizzeria.
  Future<void> _showManualEntryDialog(AppLocalizations t) async {
    final controller = TextEditingController();

    final String? entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.enterIdDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.enterIdDialogBody,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.idFieldLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(t.validate),
          ),
        ],
      ),
    );

    if (entered == null || entered.isEmpty) return;
    await _saveCardId(entered);
  }

  Widget _buildScannerWidget(AppLocalizations t) {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessingScan) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _saveCardId(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              await _scannerController.stop();
              if (!mounted) return;
              setState(() {
                _isScanning = false;
                _isLoading = false;
              });
            },
            child: Text(
              t.cancel,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCardWidget(double progress, AppLocalizations t) {
    final int remaining = (_targetPizzas - _currentPizzas).clamp(
      0,
      _targetPizzas,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (_showProgress || _errorMessage != null) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_pinkPrimary, _pinkDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _pinkDark.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.pizzasCardTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Icon(Icons.local_pizza, color: _pinkAccent, size: 32),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_customerName.isNotEmpty) ...[
                    Text(
                      (_errorMessage ?? _customerName).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  Text(
                    t.cardBalance,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.pizzasCount(_currentPizzas, _targetPizzas),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _pinkLight,
                      ),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage != null
                              ? _errorMessage!
                              : _currentPizzas >= _targetPizzas
                                  ? t.congratsRewardAvailable
                                  : t.remainingPizzas(remaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_errorMessage == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.loyaltyOffer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          t.retry,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ], // fin du bloc conditionnel showProgress
          const SizedBox(height: 35),
          Text(
            t.officialQrCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: QrImageView(
              data: _scannedCardId!,
              version: QrVersions.auto,
              size: 200,
              gapless: false,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              (_errorMessage ?? _customerName).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
