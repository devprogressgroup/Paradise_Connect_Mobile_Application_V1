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
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("Residential",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Color(blue2Color))),
                 Text("See All",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(primaryColor))),
               ],
             ),
             SizedBox(height: 15),
             _buildResidential(name: "Vista", image: logoExVista, onTap: () {
               context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 2, title: "Vista" ));
             },),
             SizedBox(height: 15),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("Commercial",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Color(blue2Color))),
                 Text("See All",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(primaryColor))),
               ],
             ),
             SizedBox(height: 15),
             _buildResidential(name: "Soho", image: logoExSoho, onTap: () {
               context.pushNamed("salesKit", extra: SalesKitDetailArgs(page: 2, title: "Soho" ));
             },),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildResidential({required String name, required String image, required VoidCallback onTap}){
  return Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 137,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Image.asset(image, height: 100),
          ),
        ),
      ),
      SizedBox(height: 15),
      Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Color(blue2Color))),

    ],
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