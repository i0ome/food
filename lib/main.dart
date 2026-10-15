import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// تنبيه: وضع كلمة المرور داخل التطبيق غير آمن. الأفضل لاحقاً Firebase Authentication.
const adminUser = 'Lymon';
const adminPass = 'Mmaymanmm2020';

String userName = '', userEmail = '', userPhone = '';

FirebaseFirestore get db => FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // بعد flutterfire configure
  runApp(const App());
}

// ===================== أدوات مساعدة =====================
const brand1 = Color(0xFFFF5722);
const brand2 = Color(0xFFFFA000);

String fmt(num v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

double unitPrice(Map<String, dynamic> m) {
  final price = (m['price'] as num).toDouble();
  final disc = ((m['discount'] as num?) ?? 0).toDouble();
  return price * (1 - disc / 100);
}

void snack(BuildContext c, String t) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

// أرقام الهاتف بصيغة دولية بدون + (مثال: 9665XXXXXXXX)
Future<void> openWhatsApp(String phone, String msg) async {
  final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> askLocation() async {
  try {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (_) {}
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lymon',
        theme: ThemeData(colorSchemeSeed: brand1, useMaterial3: true),
        builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
        home: const SplashPage(),
      );
}

// ===================== انترو Lymon المتحرك =====================
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await _c.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await askLocation(); // طلب إذن الموقع
    final sp = await SharedPreferences.getInstance();
    userName = sp.getString('name') ?? '';
    userEmail = sp.getString('email') ?? '';
    userPhone = sp.getString('phone') ?? '';
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => userName.isEmpty ? const LoginPage() : const HomePage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const word = 'Lymon';
    final logo = CurvedAnimation(parent: _c, curve: const Interval(0, 0.4, curve: Curves.elasticOut));
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [brand1, brand2],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: logo,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                ]),
                child: const Icon(Icons.delivery_dining, size: 70, color: brand1),
              ),
            ),
            const SizedBox(height: 28),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(word.length, (i) {
                  final s = 0.35 + i * 0.1;
                  final a = CurvedAnimation(parent: _c, curve: Interval(s, s + 0.25, curve: Curves.easeOut));
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(a),
                      child: Text(
                        word[i],
                        style: const TextStyle(
                            fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: const Interval(0.7, 1)),
              child: const Text('اطلب أكلك وخلنا نوصله لك',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== تسجيل الدخول =====================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool admin = false;
  bool hide = true;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();

  Widget tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool obscure = false, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Future<void> submit() async {
    if (admin) {
      if (user.text.trim() == adminUser && pass.text == adminPass) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPanel()));
      } else {
        snack(context, 'بيانات الإدارة غير صحيحة');
      }
      return;
    }
    if (name.text.trim().isEmpty) return snack(context, 'اكتب اسمك');
    if (!email.text.contains('@') || !email.text.contains('.')) return snack(context, 'البريد غير صحيح');
    if (phone.text.trim().length < 9) return snack(context, 'رقم الجوال غير صحيح');

    userName = name.text.trim();
    userEmail = email.text.trim();
    userPhone = phone.text.trim();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('name', userName);
    await sp.setString('email', userEmail);
    await sp.setString('phone', userPhone);
    db
        .collection('users')
        .doc(userPhone)
        .set({'name': userName, 'email': userEmail, 'phone': userPhone, 'createdAt': FieldValue.serverTimestamp()})
        .catchError((_) {});
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [brand1, brand2]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Icon(Icons.delivery_dining, size: 64, color: Colors.white),
                const Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('Lymon',
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) =>
                      Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 60 * (1 - v)), child: child)),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('زبون'), icon: Icon(Icons.person)),
                              ButtonSegment(value: true, label: Text('الإدارة'), icon: Icon(Icons.admin_panel_settings)),
                            ],
                            selected: {admin},
                            onSelectionChanged: (s) => setState(() => admin = s.first),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: admin
                              ? Column(key: const ValueKey('a'), children: [
                                  tf(user, 'اسم المستخدم', Icons.badge),
                                  tf(pass, 'كلمة المرور', Icons.lock,
                                      obscure: hide,
                                      suffix: IconButton(
                                        icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => hide = !hide),
                                      )),
                                ])
                              : Column(key: const ValueKey('c'), children: [
                                  tf(name, 'الاسم', Icons.person_outline),
                                  tf(email, 'البريد الإلكتروني', Icons.email_outlined, type: TextInputType.emailAddress),
                                  tf(phone, 'رقم الجوال', Icons.phone_outlined, type: TextInputType.phone),
                                ]),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: submit,
                            child: Text(admin ? 'دخول الإدارة' : 'ابدأ الطلب',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== الصفحة الرئيسية للزبون =====================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> logout(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    userName = userEmail = userPhone = '';
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أهلاً $userName 👋'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => logout(context))],
      ),
      body: ListView(children: [
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('offers').snapshots(),
          builder: (c, s) {
            if (!s.hasData || s.data!.docs.isEmpty) return const SizedBox();
            return SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                children: s.data!.docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  return Container(
                    width: 230,
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [brand1, brand2]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['title'] ?? '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(m['desc'] ?? '', style: const TextStyle(color: Colors.white)),
                    ]),
                  );
                }).toList(),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('المطاعم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('restaurants').snapshots(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return Column(
              children: s.data!.docs.map((d) {
                final m = d.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                    title: Text(m['name'] ?? ''),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => OrderPage(id: d.id, data: m))),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}

// ===================== صفحة الطلب (المنيو) =====================
class OrderPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  const OrderPage({super.key, required this.id, required this.data});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final coupon = TextEditingController();
  final Map<String, int> qty = {};
  int couponPercent = 0;
  bool busy = false;

  Future<Position> getPos() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      throw 'يجب السماح بالوصول للموقع من إعدادات الجوال';
    }
    return Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>?> nearestDriver(double lat, double lng) async {
    final snap = await db.collection('drivers').get();
    Map<String, dynamic>? best;
    double bestD = double.infinity;
    for (final d in snap.docs) {
      final m = d.data();
      final dist = Geolocator.distanceBetween(
          lat, lng, (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
      if (dist < bestD) {
        bestD = dist;
        best = m;
      }
    }
    return best;
  }

  Future<void> applyCoupon() async {
    final q = await db.collection('coupons').where('code', isEqualTo: coupon.text.trim()).get();
    if (q.docs.isEmpty) {
      setState(() => couponPercent = 0);
      if (mounted) snack(context, 'الكوبون غير صحيح');
      return;
    }
    setState(() => couponPercent = (q.docs.first['percent'] as num).toInt());
    if (mounted) snack(context, 'تم تطبيق خصم $couponPercent%');
  }

  Future<void> submit(List<QueryDocumentSnapshot> docs) async {
    final lines = <String>[];
    final orderItems = <Map<String, dynamic>>[];
    double sub = 0;
    for (final d in docs) {
      final q = qty[d.id] ?? 0;
      if (q == 0) continue;
      final m = d.data() as Map<String, dynamic>;
      final u = unitPrice(m);
      sub += u * q;
      lines.add('- ${m['name']} × $q = ${fmt(u * q)}');
      orderItems.add({'name': m['name'], 'qty': q, 'unit': u});
    }
    if (lines.isEmpty) return snack(context, 'اختر صنف واحد على الأقل');

    setState(() => busy = true);
    try {
      final pos = await getPos();
      final total = sub * (1 - couponPercent / 100);
      final r = widget.data;
      final mapLink = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

      await db.collection('orders').add({
        'restaurantId': widget.id,
        'customer': userName,
        'customerPhone': userPhone,
        'items': orderItems,
        'subtotal': sub,
        'couponPercent': couponPercent,
        'total': total,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final driver = await nearestDriver((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble());

      final restMsg = 'طلب جديد 🍽️\nالاسم: $userName\nجوال: $userPhone\n'
          '${lines.join('\n')}\nالمجموع: ${fmt(sub)}\nخصم الكوبون: $couponPercent%\n'
          'الإجمالي: ${fmt(total)}\nموقع الزبون: $mapLink';
      final driverMsg = 'مطلوب منك استلام طلب من مطعم ${r['name']} 🛵\n'
          'موقع المطعم: https://maps.google.com/?q=${r['lat']},${r['lng']}\n'
          'موقع الزبون: $mapLink\nجوال الزبون: $userPhone';

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('تم حفظ الطلب ✅'),
          content: Text('الإجمالي: ${fmt(total)}\nأرسل الرسائل عبر واتساب:'),
          actions: [
            TextButton(onPressed: () => openWhatsApp(r['phone'], restMsg), child: const Text('للمطعم')),
            if (driver != null)
              TextButton(
                  onPressed: () => openWhatsApp(driver['phone'], driverMsg),
                  child: Text('للمندوب ${driver['name']}')),
            TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('إنهاء')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.data['name'] ?? '')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('items').where('restaurantId', isEqualTo: widget.id).snapshots(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          double sub = 0;
          for (final d in docs) {
            sub += unitPrice(d.data() as Map<String, dynamic>) * (qty[d.id] ?? 0);
          }
          final total = sub * (1 - couponPercent / 100);

          return Column(children: [
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('لا توجد أصناف في هذا المطعم'))
                  : ListView(
                      children: docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final disc = ((m['discount'] as num?) ?? 0).toDouble();
                        final q = qty[d.id] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: ListTile(
                            title: Text(m['name'] ?? ''),
                            subtitle: Row(children: [
                              Text(fmt(unitPrice(m)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: brand1)),
                              if (disc > 0) ...[
                                const SizedBox(width: 8),
                                Text(fmt(m['price'] as num),
                                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text('خصم ${fmt(disc)}%',
                                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ]),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: q > 0 ? () => setState(() => qty[d.id] = q - 1) : null,
                              ),
                              Text('$q', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: brand1),
                                onPressed: () => setState(() => qty[d.id] = q + 1),
                              ),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ]),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: coupon,
                        decoration: const InputDecoration(
                            labelText: 'كوبون الخصم', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: applyCoupon, child: const Text('تطبيق')),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('الإجمالي', style: TextStyle(fontSize: 16)),
                    Text(fmt(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: busy ? null : () => submit(docs),
                      child: Text(busy ? '...' : 'تأكيد الطلب'),
                    ),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ===================== لوحة الإدارة =====================
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة الإدارة'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginPage())),
              ),
            ],
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'المطاعم'),
              Tab(text: 'الأصناف'),
              Tab(text: 'المناديب'),
              Tab(text: 'العروض'),
              Tab(text: 'الكوبونات'),
            ]),
          ),
          body: const TabBarView(children: [
            CrudTab(
              collection: 'restaurants',
              titleKey: 'name',
              fields: {'name': 'اسم المطعم', 'phone': 'واتساب (9665XXXXXXXX)', 'lat': 'خط العرض', 'lng': 'خط الطول'},
            ),
            ItemsTab(),
            CrudTab(
              collection: 'drivers',
              titleKey: 'name',
              fields: {'name': 'اسم المندوب', 'phone': 'واتساب (9665XXXXXXXX)', 'lat': 'خط العرض', 'lng': 'خط الطول'},
            ),
            CrudTab(collection: 'offers', titleKey: 'title', fields: {'title': 'عنوان العرض', 'desc': 'الوصف'}),
            CrudTab(collection: 'coupons', titleKey: 'code', fields: {'code': 'الكود', 'percent': 'نسبة الخصم %'}),
          ]),
        ),
      );
}

// ---------- الأصناف والأسعار والخصومات ----------
class ItemsTab extends StatelessWidget {
  const ItemsTab({super.key});

  Future<void> dialog(BuildContext context, {DocumentSnapshot? doc}) async {
    final rs = await db.collection('restaurants').get();
    if (rs.docs.isEmpty) {
      if (context.mounted) snack(context, 'أضف مطعماً أولاً');
      return;
    }
    final m = (doc?.data() as Map<String, dynamic>?) ?? {};
    final name = TextEditingController(text: m['name'] ?? '');
    final price = TextEditingController(text: m['price']?.toString() ?? '');
    final disc = TextEditingController(text: (m['discount'] ?? 0).toString());
    String rid = m['restaurantId'] ?? rs.docs.first.id;
    if (!rs.docs.any((d) => d.id == rid)) rid = rs.docs.first.id;
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(doc == null ? 'إضافة صنف' : 'تعديل صنف'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: rid,
                decoration: const InputDecoration(labelText: 'المطعم'),
                items: rs.docs
                    .map((d) => DropdownMenuItem(value: d.id, child: Text('${d['name']}')))
                    .toList(),
                onChanged: (v) => setS(() => rid = v!),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الصنف')),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر')),
              TextField(
                  controller: disc,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'نسبة الخصم % (0 = بدون خصم)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final data = <String, dynamic>{
                  'restaurantId': rid,
                  'name': name.text.trim(),
                  'price': double.tryParse(price.text) ?? 0,
                  'discount': (double.tryParse(disc.text) ?? 0).clamp(0, 100),
                };
                if (doc == null) {
                  await db.collection('items').add(data);
                } else {
                  await doc.reference.update(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton(onPressed: () => dialog(context), child: const Icon(Icons.add)),
        body: StreamBuilder<QuerySnapshot>(
          stream: db.collection('restaurants').snapshots(),
          builder: (c, rs) {
            final names = <String, String>{};
            for (final d in rs.data?.docs ?? []) {
              names[d.id] = '${d['name']}';
            }
            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('items').snapshots(),
              builder: (c, s) {
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(
                  children: s.data!.docs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    final disc = ((m['discount'] as num?) ?? 0);
                    return ListTile(
                      title: Text('${m['name']}'),
                      subtitle: Text(
                          '${names[m['restaurantId']] ?? '—'} • السعر ${fmt(m['price'] as num)}'
                          '${disc > 0 ? ' • خصم ${fmt(disc)}%' : ''}'),
                      onTap: () => dialog(context, doc: d),
                      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => d.reference.delete()),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      );
}

// ---------- تبويب عام للإضافة والحذف ----------
class CrudTab extends StatelessWidget {
  final String collection;
  final String titleKey;
  final Map<String, String> fields;
  const CrudTab({super.key, required this.collection, required this.titleKey, required this.fields});

  void add(BuildContext context) {
    final ctrls = {for (final k in fields.keys) k: TextEditingController()};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.entries
                .map((e) => TextField(controller: ctrls[e.key], decoration: InputDecoration(labelText: e.value)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final data = <String, dynamic>{};
              ctrls.forEach((k, c) {
                data[k] = (k == 'lat' || k == 'lng')
                    ? double.tryParse(c.text) ?? 0
                    : (k == 'percent' ? int.tryParse(c.text) ?? 0 : c.text.trim());
              });
              await db.collection(collection).add(data);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton(onPressed: () => add(context), child: const Icon(Icons.add)),
        body: StreamBuilder<QuerySnapshot>(
          stream: db.collection(collection).snapshots(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(
              children: s.data!.docs.map((d) {
                final m = d.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text('${m[titleKey]}'),
                  subtitle: Text(m.entries.where((e) => e.key != titleKey).map((e) => '${e.value}').join(' • ')),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => d.reference.delete()),
                );
              }).toList(),
            );
          },
        ),
      );
}