import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../data/arguments/attandance_args.dart';

class AttandancePage extends StatefulWidget {
  const AttandancePage({super.key});

  @override
  State<AttandancePage> createState() => _AttandancePageState();
}

class _AttandancePageState extends State<AttandancePage> {
  int selectedIndex = 0;
  late PageController _pageController;
  final double officeLat =  -6.1416575;
  final double officeLng = 106.8659419;
  final double radiusMeter = 1050;
  StreamSubscription<Position>? _positionStream;

  String? _address;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => selectedIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // cek GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS belum aktif'),
        ),
      );
      return false;
    }

    // cek permission
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi ditolak permanen, buka settings'),
        ),
      );

      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _initLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      Geolocator.distanceBetween(
        officeLat,
        officeLng,
        position.latitude,
        position.longitude,
      );

      setState(() {
      });

      await _getAddressFromLatLng(position);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      setState(() {
        _address =
            "${place.street}, ${place.subLocality}, ${place.locality}, "
            "${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        _address = "Alamat tidak ditemukan";
      });
    }
  }

  Future<Position?> _getCurrentLocationOnce() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleMoveCamera(String title)async{
     final position = await _getCurrentLocationOnce();

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lokasi belum terdeteksi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final distance = Geolocator.distanceBetween(
      officeLat,
      officeLng,
      position.latitude,
      position.longitude,
    );

    final isInRadius = distance <= radiusMeter;

    if (!isInRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Kamu di luar area kantor\n"
            "Jarak: ${distance.toStringAsFixed(0)} meter\n"
            "Radius: $radiusMeter meter\n"
            "Lokasi: ${_address ?? 'unknown'}",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.pushNamed(
      'camera',
      extra: AttandanceArgs(
        type: title,
        location:_address,
        time: DateHelper.formatTime(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context,'Attandance', colorBg: Color(primaryColor),colorBack: Color(whiteColor),colorTitle: Color(whiteColor), iconRight: Icons.arrow_back, iconRightOnTap: (){ context.go('/');}, colorIconRight: Color(whiteColor)),
            SizedBox(
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderProfile(),
                  _buildFloatingCard(),
                ],
              ),
            ),
            SizedBox(height: 60,),
            Expanded(
              child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                borderRadius: BorderRadius.circular(16),
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Log", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(blackColor)),),
                    SizedBox(height: 5),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 20,
                        itemBuilder: (_, __) => _buildCard(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard(){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: GestureDetector(
        onTap: () {
        _showAttendanceDialog();
        },  
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 70,
              height: 40,
              decoration: BoxDecoration(
                color: Color(grey10Color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("06", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(blackColor)),),
                  Text("Mon", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100, color: Color(blackColor)),),
                ],
              )),
            ),
            SizedBox(width:2),
            Container(
              height: 40,
              width: 70,
              child: Column(
                children: [
                  Icon(Icons.access_time_filled, size: 17,color: Color(greenPercentColor),),
                  Text("08:00 AM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100, color: Color(blackColor)),),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 2,
              decoration: BoxDecoration(
                color: Color(grey10Color),
              ),
            ),
            Container(
              height: 40,
              width: 70,
              child: Column(
                children: [
                  Icon(Icons.access_time_filled, size: 17,color: Color(redPeriodColor),),
                  Text("08:00 AM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100, color: Color(blackColor)),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderProfile() {
    return Container(
      height: 160,
      color: Color(primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.network( "https://i.pravatar.cc/150?img=1", width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Haris",style: TextStyle(color: Color(whiteColor),fontSize: 14,fontWeight: FontWeight.bold)),
                  Text("Mobile Developer",style: TextStyle(color: Color(whiteColor),fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard() {
    return Positioned(
     top: 55, 
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildTabBar(),
            SizedBox(height: 5),
            _buildPageView(),
          ],
        ),
      ),
    );
  }


  Widget _buildTabBar() {
    const double tabHeight = 35;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Container(
        height: tabHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? 0)
                      : selectedIndex.toDouble();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final tabWidth = constraints.maxWidth / 2;

                      return Transform.translate(
                        offset: Offset(tabWidth * page, 0),
                        child: Container(
                          width: tabWidth,
                          height: tabHeight,
                          decoration: BoxDecoration(
                            color: Color(primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              /// 🔥 TEXT TAB
              Row(
                children: List.generate(2, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(index),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, _) {
                            final page = _pageController.hasClients
                                ? (_pageController.page ?? 0)
                                : selectedIndex.toDouble();

                            final isActive = (page - index).abs() < 0.5;

                            return Text(
                              index == 0 ? "Check In" : "Check Out",
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPageView() {
    return Container(
      height: 190,
      child: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        onPageChanged: (index) {
          setState(() => selectedIndex = index);
        },
        children: [
          _buildCheckIn(),
          _buildCheckOut(),
        ],
      ),
    );
    }
  Widget _buildCheckForm({required String title}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateHelper.formatTime(DateTime.now()),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          DateHelper.formatDayDate(DateTime.now()),
          style: TextStyle(fontSize: 11, color: Color(grey12Color)),
        ),
        SizedBox(height: 8),

    
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () async {
             _handleMoveCamera(title);
            },
            child: Container(
              height: 90,
              width: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(primaryColor).withOpacity(0.1),
              ),
              child: Container(
                height: 80,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(primaryColor).withOpacity(0.2),
                ),
                child: Container(
                  height: 70,
                  width: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(primaryColor),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(whiteColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 12),
        Text(
          "Please $title!",
          style: TextStyle(fontSize: 12, color: Color(grey12Color)),
        ),
      ],
    );
  }  

  Widget _buildCheckOut() {
    return _buildCheckForm(title: "Clock Out");
  }

  Widget _buildCheckIn() {
    return _buildCheckForm(title: "Clock In");
  }

    
  void _showAttendanceDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      "https://i.pravatar.cc/150?img=1",
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.access_time_filled,"08.00 AM",Color(greenPercentColor),),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today,DateHelper.formatDayDate(DateTime.now()),Color(primaryColor),),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.map,"Sunter, Jakarta Utara",Color(primaryColor),),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.notes,"---",Color(primaryColor),),
                  SizedBox(height: 20),
      
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}