import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/widget/custom_search_field.dart';
import '../../data/arguments/saleskit_detail_args.dart';

class SalesKitPage extends StatefulWidget {
  final SalesKitDetailArgs args;
  const SalesKitPage({super.key, required this.args});

  @override
  State<SalesKitPage> createState() => _SalesKitPageState();
}

class _SalesKitPageState extends State<SalesKitPage> {
  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();
  bool isOpenRedential = true;
  bool isOpenCommercial = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: widget.args.page == 1 ? _buildDetail(): widget.args.page == 2 ? _buildShare(): _builSalsesKitScreen()
      ),
    );
  }

  Widget _buildShare(){
    return Column(
      children: [
        customHeader(context, widget.args.title!, isBack: true),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
            
             SizedBox(height: 15),
             _buildButtonBorder(title: "Price List",colorBg: whiteColor,colorTitle: primaryColor,  logo: icPriceList, onTap: () {
               
             }),
             SizedBox(height: 15),
             _buildButtonBorder(title: "EBrouchure",colorBg: whiteColor,colorTitle: primaryColor,  logo: icEBrouchure, onTap: () {
               
             }),
             SizedBox(height: 15),
             _buildButtonBorder(title: "Product Knowledge",colorBg: whiteColor,colorTitle: primaryColor,  logo: icProductKnowlage, onTap: () {
               
             }),

             SizedBox(height: 30),
             _buildButtonBorder(title: "Share",colorBg: blue3Color,colorTitle: whiteColor,  logo: icShare, onTap: () {
               
             }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonBorder({required String title, required int colorBg,required int colorTitle, required VoidCallback onTap, required String logo}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(colorBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(primaryColor)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(logo, height: 20, color: Color(colorTitle)),
              SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(colorTitle))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(){
    return Column(
      children: [
        customHeader(context, widget.args.title ?? "SalesKit", isBack: true),
          SizedBox(height: 1),
        _dropdown("Residential", () {
          setState(() {
            isOpenRedential = !isOpenRedential;
          });
        }, isOpenRedential, Column(
            children: [
              SizedBox(height: 5),
             _buildResidential( image: logoExVista, onTap: () {
               context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 2, title: "Vista" ));
             },),
             SizedBox(height: 5),
             _buildResidential( image: logoExAdventures, onTap: () {
               context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 2, title: "Adventures" ));
             },),
            SizedBox(height: 25),

            ],
          ),
        ),
        _dropdown("Commercial", () {
          setState(() {
            isOpenCommercial = !isOpenCommercial;
          });
        }, isOpenCommercial, Column(
            children: [
              SizedBox(height: 5),
             _buildResidential( image: logoExSoho, onTap: () {
               context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 2, title: "Soho" ));
             },),
            ],
          ),
        ),     
      ],
    );
  }

  Widget _dropdown(String hint,VoidCallback onTap, bool isOpen, Widget child){
     return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(blackColor).withOpacity(0.06),
            blurRadius: 58,
            offset: Offset(0,6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              color: Color(whiteColor),
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down, size: 35,
                  ),
                ],
              ),
            ),
          ),
      
      
          /// 🔥 CONTENT DINAMIS
          if (isOpen)
            Container(
              width: double.infinity,
              child: child,
            ),
        ],
      ),
    );
  }


  Widget _buildResidential({required String image, required VoidCallback onTap}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        height: 137,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Image.asset(image, height: 100),
        ),
      ),
    );
  }

  Widget _builSalsesKitScreen(){
    return Column(
      children: [
        customHeader(context, "SalesKit", isBack: false),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              customSearchField(controller: searchTC, focusNode: searchFN),
              SizedBox(height: 15),
              Text("Projects",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Color(blue2Color))),
              SizedBox(height: 15),
              buildProjectBanner(
                backgroundImage: bannerSaleskitProyek,
                logoImage: logoParadiseResort,
                title: "Paradise Resort City",
                subtitle: "500 hectare Eco Urban City in South Serpong",
                ontap: (){
                  context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 1, title: "Paradise Resort City" ));
                }
              ),
              buildProjectBanner(
                backgroundImage: bannerSaleskitProyek,
                logoImage: logoParadiseSerpong,
                title: "Paradise Serpong City",
                subtitle: "500 hectare Eco Urban City in South Serpong",
                ontap: (){context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 1, title: "Paradise Serpong City" ));}
              ),
              buildProjectBanner(
                backgroundImage: bannerSaleskitProyek,
                logoImage: logoParadiseSerpong2,
                title: "Paradise Serpong City 2",
                subtitle: "500 hectare Eco Urban City in South Serpong",
                ontap: (){
                  context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 1, title: "Paradise Serpong City 2" ));
                }
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget buildProjectBanner({required String  backgroundImage,required String logoImage,required String title,required String subtitle,double height = 141.0, required VoidCallback ontap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: ontap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: height,
                width: double.infinity,
                color: Color(blue2Color).withOpacity(0.7),
              ),
              SizedBox(
                height: height,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      logoImage,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(whiteColor),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w200,
                          color: Color(whiteColor),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}