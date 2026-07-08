import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';

class QrScannerPage extends StatefulWidget {
  final String sessionId; 
  const QrScannerPage({super.key, required this.sessionId});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late IO.Socket socket;
  String? qrBase64;
  bool isConnected = false;
  bool isTriggering = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('qr_scanner');
    initSocket();
    triggerLaravelQR();
  }

  void initSocket() {
    socket = IO.io(ApiConstants.waServerURL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {});

    socket.on('qr', (data) {
      if (!mounted) return;

   
      if (data is Map && data['sessionId'] != null && data['sessionId'] != widget.sessionId) {
        return;
      }

      setState(() {
        if (data is Map) {
           qrBase64 = data['qr'].toString().split(',').last;
        } else {
           qrBase64 = data.toString().split(',').last;
        }
        isTriggering = false;
      });
    });

    socket.on('status', (data) {
      if (!mounted) return;
      
      if (data is Map && data['status'] == 'CONNECTED') {
        setState(() {
          isConnected = true;
          isTriggering = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });

    socket.onDisconnect((_) {});
  }

  Future<void> triggerLaravelQR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          errorMessage = "Sesi autentikasi habis, silakan login kembali.";
          isTriggering = false;
        });
        return;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/whatsapp/qr/session',
        data: {'session': widget.sessionId},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = "Server merespon dengan status: ${response.statusCode}";
          isTriggering = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Gagal menghubungi server utama";
        isTriggering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      appBar: AppBar(
        title: const Text("Scan WhatsApp QR", style: TextStyle(color: Color(blackColor))),
        backgroundColor: Color(whiteColor),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(blackColor)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isConnected) ...[
                const Icon(Icons.check_circle, color: Color(greenMaterialColor), size: 80),
                const SizedBox(height: 16),
                const Text("WhatsApp Berhasil Terhubung!", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ] else if (errorMessage.isNotEmpty) ...[
                const Icon(Icons.error_outline, color: Color(redAccentColor), size: 60),
                const SizedBox(height: 16),
                Text(errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    AnalyticsService.logEvent('qr_scanner_retry_qr');
                    setState(() {
                      errorMessage = '';
                      isTriggering = true;
                    });
                    triggerLaravelQR();
                  },
                  child: const Text("Coba Lagi")
                )
              ] else ...[
                const Text("Tautkan Perangkat", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Buka WhatsApp > Perangkat Tertaut > Tautkan Perangkat", 
                  textAlign: TextAlign.center, style: TextStyle(color: Color(greyShade500), fontSize: 13)),
                
                const SizedBox(height: 40),

                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Color(greyShade50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(greyShade300)!),
                    boxShadow: [
                      BoxShadow(
                        color: Color(blackColor).withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: qrBase64 == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 16),
                              Text("Menunggu QR Code...", style: TextStyle(fontSize: 12, color: Color(greyShade500)))
                            ],
                          )
                        : Image.memory(
                            base64Decode(qrBase64!),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                const SizedBox(height: 40),
                
                const Text("Pastikan HP Anda terhubung ke internet", style: TextStyle(color: Color(greyShade500), fontSize: 12)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('qr_scanner_regenerate_qr');
                    setState(() => qrBase64 = null);
                    triggerLaravelQR();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Refresh QR Code")
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.off('qr');
    socket.off('status');
    socket.disconnect();
    super.dispose();
  }
}
