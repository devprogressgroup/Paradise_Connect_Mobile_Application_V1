import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

Widget _shimmerWrap({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Color(grey8Color),
    highlightColor: Color(grey4Color),
    child: child,
  );
}


class ShimmerContactItem extends StatelessWidget {
  const ShimmerContactItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ShimmerBox(width: double.infinity, height: 14),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 140, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ShimmerBox(width: 27, height: 27, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

Widget buildContactListShimmer() {
  return ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 8,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => const ShimmerContactItem(),
  );
}

Widget buildContactPageShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        SizedBox(
          height: 50,
          child: Row(
            children: [
              _ShimmerBox(width: 90, height: 36, borderRadius: 12),
              const SizedBox(width: 10),
              _ShimmerBox(width: 90, height: 36, borderRadius: 12),
                const SizedBox(width: 10),
              _ShimmerBox(width: 110, height: 36, borderRadius: 12),
              const SizedBox(width: 10),
              _ShimmerBox(width: 40, height: 36, borderRadius: 12),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        ...List.generate(8, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShimmerBox(width: double.infinity, height: 14),
                            const SizedBox(height: 6),
                            _ShimmerBox(width: 140, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _ShimmerBox(width: 27, height: 27, borderRadius: 4),
              ],
            ),
          ),
        )),
      ],
    ),
  );
}



class ShimmerActivityItem extends StatelessWidget {
  const ShimmerActivityItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: Color(grey3Color), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  
                  
                  
                  
                  
                  
                  
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          
                          
                          
                          _ShimmerBox(width: double.infinity, height: MediaQuery.of(context).size.height * 0.25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildActivityShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => const ShimmerActivityItem(),
  );
}



class ShimmerAttachmentItem extends StatelessWidget {
  const ShimmerAttachmentItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _ShimmerBox(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 13),
                  const SizedBox(height: 5),
                  _ShimmerBox(width: 120, height: 11),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 160, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _ShimmerBox(width: 44, height: 44, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

Widget buildAttachmentShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => const ShimmerAttachmentItem(),
  );
}



class ShimmerInboxItem extends StatelessWidget {
  const ShimmerInboxItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const _ShimmerBox(width: 46, height: 40, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShimmerBox(width: 150, height: 13),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 100, height: 11),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShimmerBox(width: 50, height: 10),
                      const SizedBox(height: 6),
                      const _ShimmerBox(width: 18, height: 18, borderRadius: 9),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildInboxShimmer() {
  return Container(
    decoration: BoxDecoration(
      color: Color(whiteColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      separatorBuilder: (_, __) => Divider(height: 1, color: Color(greyShade100)),
      itemBuilder: (_, __) => const ShimmerInboxItem(),
    ),
  );
}

Widget buildHomeTaskShimmer() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _shimmerWrap(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 130, height: 16),
            _ShimmerBox(width: 50, height: 12),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 240,
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(greyShade500).withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _shimmerWrap(
          child: Column(
            children: List.generate(3, (_) => Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6,vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                borderRadius: BorderRadius.circular(8),
              ),
             
            )),
          ),
        ),
      ),
    ],
  );
}

Widget buildProspectStatusShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
          
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: List.generate(6, (i) => Container(
              height: 44,
              margin: EdgeInsets.only(left: 14, right: 14, top: i == 0 ? 8 : 0, bottom: 8),
              decoration: BoxDecoration(color: Color(whiteColor), borderRadius: BorderRadius.circular(6)),
            )),
          ),
        ),
      ],
    ),
  );
}


Widget buildHomeChartShimmer() {
  return _shimmerWrap(
    child: SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            7,
            (i) => _ShimmerBox(
              width: 28,
              height: 40.0 + (i % 3) * 30,
              borderRadius: 4,
            ),
          ),
        ),
      ),
    ),
  );
}



class ShimmerSaleskitCard extends StatelessWidget {
  const ShimmerSaleskitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 141,
            width: double.infinity,
            color: Color(whiteColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _ShimmerBox(width: 60, height: 40, borderRadius: 8),
                const SizedBox(height: 8),
                _ShimmerBox(width: 160, height: 14),
                const SizedBox(height: 6),
                _ShimmerBox(width: 220, height: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildSaleskitShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 5,
    itemBuilder: (_, __) => const ShimmerSaleskitCard(),
  );
}



Widget buildActivityLogShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 4,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Container(width: 5, decoration: BoxDecoration(color: Color(whiteColor), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ShimmerBox(width: 130, height: 14),
                                  const SizedBox(height: 5),
                                  _ShimmerBox(width: 100, height: 11),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _ShimmerBox(width: 40, height: 11),
                              const SizedBox(height: 4),
                              _ShimmerBox(width: 56, height: 18, borderRadius: 4),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      _ShimmerBox(width: 180, height: 11),
                      const SizedBox(height: 10),
                      
                      Row(
                        children: [
                          _ShimmerBox(width: 100, height: 100, borderRadius: 8),
                          const SizedBox(width: 8),
                          _ShimmerBox(width: 100, height: 100, borderRadius: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    ),
  );
}


Widget buildAttendanceFloatingCardShimmer() {
  return _shimmerWrap(
    child: Column(
      children: [
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(22.5),
            ),
          ),
        ),
        const SizedBox(height: 5),
        
        SizedBox(
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerBox(width: 110, height: 22, borderRadius: 4),
              const SizedBox(height: 6),
              _ShimmerBox(width: 80, height: 13, borderRadius: 4),
              const SizedBox(height: 14),
              const _ShimmerBox(width: 90, height: 90, borderRadius: 45),
              const SizedBox(height: 12),
              _ShimmerBox(width: 120, height: 12, borderRadius: 4),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget buildDashboardTopShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 200, height: 16, borderRadius: 4),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const _ShimmerBox(width: 22, height: 22, borderRadius: 4),
              const SizedBox(width: 10),
              _ShimmerBox(width: 160, height: 14, borderRadius: 4),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget buildDashboardChartHeaderShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 60, height: 10, borderRadius: 4),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 100, height: 14, borderRadius: 4),
            _ShimmerBox(width: 60, height: 14, borderRadius: 4),
          ],
        ),
      ],
    ),
  );
}


Widget buildInboxFilterShimmer() {
  return _shimmerWrap(
    child: Row(
      children: [
        _ShimmerBox(width: 80, height: 32, borderRadius: 20),
        const SizedBox(width: 8),
        _ShimmerBox(width: 100, height: 32, borderRadius: 20),
        const SizedBox(width: 8),
        _ShimmerBox(width: 80, height: 32, borderRadius: 20),
      ],
    ),
  );
}


Widget buildInboxTabBarShimmer() {
  return _shimmerWrap(
    child: Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Color(greyShade300),
                borderRadius: BorderRadius.circular(27),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Color(greyShade300),
                borderRadius: BorderRadius.circular(27),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


Widget buildLogHeaderShimmer() {
  return _shimmerWrap(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShimmerBox(width: 130, height: 18, borderRadius: 4),
        _ShimmerBox(width: 90, height: 32, borderRadius: 20),
      ],
    ),
  );
}


Widget buildAttendanceTabButtonShimmer() {
  return _shimmerWrap(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _ShimmerBox(width: double.infinity, height: 30, borderRadius: 12)),
          const SizedBox(width: 8),
          Expanded(child: _ShimmerBox(width: double.infinity, height: 30, borderRadius: 12)),
        ],
      ),
    ),
  );
}



Widget buildAttendanceShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _ShimmerBox(width: 70, height: 40, borderRadius: 6),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 60, height: 11),
                ],
              ),
            ),
            Container(width: 2, height: 40, color: Color(whiteColor)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 60, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



Widget buildProfileShimmer() {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: _shimmerWrap(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 60, height: 60, borderRadius: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: double.infinity, height: 16),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 120, height: 12),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ShimmerBox(width: 180, height: 12),
            const SizedBox(height: 16),
            Container(height: 1, color: Color(whiteColor)),
            const SizedBox(height: 16),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 80, height: 12),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14)),
                const SizedBox(width: 20),
                Expanded(child: _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}



Widget buildNotifShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 8,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 140, height: 13),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 160, height: 11),
                    const SizedBox(height: 4),
                    _ShimmerBox(width: 100, height: 10),
                  ],
                ),
              ],
            ),
            const _ShimmerBox(width: 30, height: 30, borderRadius: 4),
          ],
        ),
      ),
    ),
  );
}


Widget buildSiteplanShimmer() {
  return _shimmerWrap(
    child: Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 500,
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
       
      ],
    ),
  );
}



class ShimmerMessageItem extends StatelessWidget {
  final bool isMe;
  const ShimmerMessageItem({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: isMe ? _buildRight() : _buildLeft(),
      ),
    );
  }

  Widget _buildLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShimmerBox(width: 80, height: 11),
                const SizedBox(width: 6),
                _ShimmerBox(width: 40, height: 10),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 180,
              height: 36,
              decoration: BoxDecoration(
                color: Color(whiteColor),
                borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRight() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShimmerBox(width: 40, height: 10),
              const SizedBox(width: 6),
              _ShimmerBox(width: 80, height: 11),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 180,
            height: 36,
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildMessageShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    reverse: true,
    itemCount: 10,
    itemBuilder: (_, i) => ShimmerMessageItem(isMe: i % 3 == 0),
  );
}


Widget buildActivityPageShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        ...List.generate(6, (_) => Container(
          margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 140, height: 13),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 100, height: 11),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 120, height: 10),
                    ],
                  ),
                ],
              ),
              const _ShimmerBox(width: 30, height: 30, borderRadius: 4),
            ],
          ),
        )),
      ],
    ),
  );
}



Widget buildTaskShimmer() {
  return _shimmerWrap(
    child: Column(
      children: List.generate(
        6,
        (_) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(whiteColor))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 120, height: 14),
                      const SizedBox(height: 5),
                      _ShimmerBox(width: 100, height: 12),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 140, height: 12),
                    ],
                  ),
                ],
              ),
              const _ShimmerBox(width: 30, height: 30, borderRadius: 4),
            ],
          ),
        ),
      ),
    ),
  );
}


Widget _buildShimmerGridCard() {
  return Container(
    
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: _ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 6),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: _ShimmerBox(width: double.infinity, height: 12 ,borderRadius: 4,),
        ),
      ],
    ),
  );
}

Widget buildSaleskitDetailShimmer() {
  return _shimmerWrap(
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.1,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildShimmerGridCard(),
    ),
  );
}


Widget buildContactHeaderNameShimmer() {
  return _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 60, height: 11, borderRadius: 4),
        const SizedBox(height: 6),
        _ShimmerBox(width: 160, height: 20, borderRadius: 4),
      ],
    ),
  );
}


Widget buildApprovalShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(width: 140, height: 16),
                _ShimmerBox(width: 70, height: 24, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 12),
            _ShimmerBox(width: 180, height: 12),
            const SizedBox(height: 8),
            _ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _ShimmerBox(width: 220, height: 12),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ShimmerBox(width: 90, height: 36, borderRadius: 8),
                const SizedBox(width: 8),
                _ShimmerBox(width: 90, height: 36, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


class ShimmerBottomNav extends StatelessWidget {
  final int itemCount;
  final double itemSize;

  const ShimmerBottomNav({super.key, this.itemCount = 4, this.itemSize = 40});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          itemCount,
          (_) => _ShimmerBox(width: itemSize, height: itemSize, borderRadius: 8),
        ),
      ),
    );
  }
}


Widget buildFormShimmer({bool showHeader = true}) {
  Widget fieldRow({double labelWidth = 100, double fieldHeight = 44}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: labelWidth, height: 10),
            const SizedBox(height: 6),
            _ShimmerBox(width: double.infinity, height: fieldHeight),
          ],
        ),
      );

  final formContent = _shimmerWrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldRow(labelWidth: 110),           
        fieldRow(labelWidth: 80),            
        fieldRow(labelWidth: 60),            
        fieldRow(labelWidth: 120),           
        fieldRow(labelWidth: 90),            
        fieldRow(labelWidth: 70),            
        fieldRow(labelWidth: 70),            
        fieldRow(labelWidth: 40, fieldHeight: 80), 
        _ShimmerBox(width: double.infinity, height: 48, borderRadius: 12), 
      ],
    ),
  );

  if (!showHeader) return formContent;

  return SafeArea(
    child: Column(
      children: [
        _shimmerWrap(
          child: Container(
            height: 64,
            color: Color(whiteColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const _ShimmerBox(width: 27, height: 27, borderRadius: 14),
                const SizedBox(width: 10),
                const _ShimmerBox(width: 130, height: 18),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: formContent,
          ),
        ),
      ],
    ),
  );
}
