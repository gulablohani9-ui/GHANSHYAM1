import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

void main() => runApp(const VastuApp());

class VastuApp extends StatelessWidget {
  const VastuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Vastu Plot + Chakra',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2f6b3a))),
    home: const HomePage(),
  );
}

class BP { Offset p; BP(this.p); }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  File? plot;
  final pts = <BP>[];
  final chakras = <File>[];
  String? chakraFolder;
  bool deleteMode = false;
  double plotDegree = 0;
  double chakraDegree = 0;

  final nameCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final mobileCtl = TextEditingController();

  @override void dispose() {
    nameCtl.dispose(); addressCtl.dispose(); mobileCtl.dispose(); super.dispose();
  }

  Future<void> pickPlot() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x != null) setState(() { plot = File(x.path); pts.clear(); });
  }

  Future<void> chooseChakraFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'CHKRA folder select करें');
    if (path == null) return;
    setState(() => chakraFolder = path);
    await refreshChakras();
  }

  Future<void> refreshChakras() async {
    if (chakraFolder == null) return;
    final dir = Directory(chakraFolder!);
    if (!await dir.exists()) return;
    final allowed = {'.png','.jpg','.jpeg','.webp'};
    final found = <File>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is File && allowed.contains(p.extension(e.path).toLowerCase())) found.add(e);
    }
    found.sort((a,b)=>p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    if (!mounted) return;
    setState(() => chakras
      ..clear()
      ..addAll(found));
  }

  Future<void> makePdf() async {
    if (plot == null || chakras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plot और कम से कम 1 Chakra जरूरी है।')));
      return;
    }
    final doc = pw.Document();
    final plotBytes = await plot!.readAsBytes();

    // Cover page: client information + plot.
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.all(28),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Vastu Plot + Chakra Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 18),
          pw.Text('Client Name: ${nameCtl.text.trim()}'),
          pw.Text('Address: ${addressCtl.text.trim()}'),
          pw.Text('Mobile: ${mobileCtl.text.trim()}'),
          pw.SizedBox(height: 14),
          pw.Text('Plot / North Degree: ${plotDegree.toStringAsFixed(1)}°'),
          pw.Text('Total Chakra Pages: ${chakras.length}'),
          pw.SizedBox(height: 18),
          pw.Expanded(child: pw.Center(child: pw.Image(pw.MemoryImage(plotBytes), fit: pw.BoxFit.contain))),
          pw.SizedBox(height: 8),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Ghanshyam Lohani', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        ]),
      ),
    ));

    // One page per Chakra: plot with the selected chakra over it.
    for (int i = 0; i < chakras.length; i++) {
      final cb = await chakras[i].readAsBytes();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(children: [
          pw.Text('Chakra ${i + 1}  •  ${p.basename(chakras[i].path)}', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Expanded(child: pw.Center(child: pw.Stack(children: [
            pw.Positioned.fill(child: pw.Image(pw.MemoryImage(plotBytes), fit: pw.BoxFit.contain)),
            pw.Center(child: pw.Transform.rotate(
              angle: chakraDegree * math.pi / 180,
              child: pw.Opacity(opacity: .78, child: pw.Image(pw.MemoryImage(cb), width: 360, height: 360, fit: pw.BoxFit.contain)),
            )),
          ]))),
          pw.Text('Plot Degree: ${plotDegree.toStringAsFixed(1)}°   |   Chakra Degree: ${chakraDegree.toStringAsFixed(1)}°'),
          pw.SizedBox(height: 4),
          pw.Text('Ghanshyam Lohani', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ]),
      ));
    }

    final bytes = await doc.save();
    // Save to app's documents folder so it can be opened/shared from the app.
    final base = Directory('/storage/emulated/0/Download');
    Directory target = base;
    if (!await target.exists()) {
      target = await Directory.systemTemp.createTemp('vastu_report_');
    }
    final file = File(p.join(target.path, 'Vastu_Plot_Chakra_Report.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF तैयार: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vastu Plot + Chakra')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('1. Client Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: addressCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: mobileCtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
      const SizedBox(height: 16),

      Text('2. Plot Photo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: pickPlot, icon: const Icon(Icons.photo_library), label: const Text('Plot Photo Select करें')),
      const SizedBox(height: 12),

      Text('3. Plot Boundary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const Text('जितने चाहें red dots लगाएँ। Dot को drag करें; Delete mode में long-press करके हटाएँ।'),
      Row(children: [
        Expanded(child: FilledButton.tonal(onPressed: () => setState(() => deleteMode = false), child: const Text('Add / Move'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => setState(() => deleteMode = true), child: const Text('Delete'))),
      ]),
      const SizedBox(height: 8),
      if (plot == null)
        Container(height: 280, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)), child: const Text('Plot photo select करें'))
      else
        PlotEditor(image: plot!, points: pts, deleteMode: deleteMode, onChanged: () => setState(() {})),
      const SizedBox(height: 12),

      Text('4. Plot / North Degree', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(labelText: 'Plot Degree', suffixText: '°', border: OutlineInputBorder()),
        onChanged: (v) { final n = double.tryParse(v); if (n != null) setState(() { plotDegree = ((n % 360) + 360) % 360; chakraDegree = plotDegree; }); },
      ),
      const SizedBox(height: 16),

      Text('5. CHKRA Folder', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: chooseChakraFolder, icon: const Icon(Icons.folder_open), label: const Text('CHKRA Folder Select करें')),
      if (chakraFolder != null) Text('Folder: $chakraFolder', maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: refreshChakras, icon: const Icon(Icons.refresh), label: const Text('Refresh CHKRA Folder')),
      Text('${chakras.length} Chakra images मिलीं'),
      const SizedBox(height: 14),

      if (plot != null && chakras.isNotEmpty) ...[
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Viewer(plot: plot!, points: pts, chakras: chakras, plotDegree: plotDegree, initialChakraDegree: chakraDegree)),), icon: const Icon(Icons.layers), label: const Text('Plot के ऊपर Chakra देखें')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: makePdf, icon: const Icon(Icons.picture_as_pdf), label: Text('${chakras.length + 1} Page PDF बनाएं')),
      ],
    ]),
  );
}

class PlotEditor extends StatelessWidget {
  final File image; final List<BP> points; final bool deleteMode; final VoidCallback onChanged;
  const PlotEditor({super.key, required this.image, required this.points, required this.deleteMode, required this.onChanged});
  @override Widget build(BuildContext c) => LayoutBuilder(builder: (c,b) {
    final w=b.maxWidth,h=w*.72;
    return GestureDetector(
      onTapDown:(d){if(!deleteMode){points.add(BP(d.localPosition));onChanged();}},
      child:SizedBox(width:w,height:h,child:Stack(children:[
        Positioned.fill(child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(image,fit:BoxFit.fill))),
        Positioned.fill(child:CustomPaint(painter:BPainter(points))),
        for(int i=0;i<points.length;i++) Positioned(
          left:points[i].p.dx-14,top:points[i].p.dy-14,
          child:GestureDetector(
            onPanUpdate:(d){if(!deleteMode){points[i].p+=d.delta;onChanged();}},
            onLongPress:(){if(deleteMode){points.removeAt(i);onChanged();}},
            child:Container(width:28,height:28,alignment:Alignment.center,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:Text('${i+1}',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold))),
          )),
      ])));
  });
}
class BPainter extends CustomPainter {
  final List<BP> p; BPainter(this.p);
  @override void paint(Canvas c,Size s){if(p.length<2)return;final q=Paint()..color=Colors.green..strokeWidth=3..style=PaintingStyle.stroke;final x=Path()..moveTo(p[0].p.dx,p[0].p.dy);for(final a in p.skip(1))x.lineTo(a.p.dx,a.p.dy);if(p.length>2)x.close();c.drawPath(x,q);}
  @override bool shouldRepaint(covariant BPainter old)=>true;
}

class Viewer extends StatefulWidget {
  final File plot; final List<BP> points; final List<File> chakras; final double plotDegree, initialChakraDegree;
  const Viewer({super.key,required this.plot,required this.points,required this.chakras,required this.plotDegree,required this.initialChakraDegree});
  @override State<Viewer> createState()=>_ViewerState();
}
class _ViewerState extends State<Viewer>{
  late final PageController pc; int page=0; late double cd;
  @override void initState(){super.initState();pc=PageController();cd=widget.initialChakraDegree;}
  @override void dispose(){pc.dispose();super.dispose();}
  void setCd(double x)=>setState(()=>cd=((x%360)+360)%360);
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text('Plot + Chakra  ${page+1}/${widget.chakras.length}')),
    body:Column(children:[
      Expanded(child:PageView.builder(controller:pc,itemCount:widget.chakras.length,onPageChanged:(i)=>setState(()=>page=i),itemBuilder:(_,i)=>pageView(widget.chakras[i]))),
      Material(elevation:8,child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
        Row(children:[Text('Plot: ${widget.plotDegree.toStringAsFixed(1)}°',style:const TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text('Chakra: ${cd.toStringAsFixed(1)}°',style:const TextStyle(fontWeight:FontWeight.bold))]),
        Slider(min:0,max:360,value:cd,onChanged:setCd),
        Row(children:[
          Expanded(child:OutlinedButton(onPressed:()=>setCd(cd-1),child:const Text('-1°'))),
          const SizedBox(width:8),
          Expanded(child:OutlinedButton(onPressed:()=>setCd(cd+1),child:const Text('+1°'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton(onPressed:()=>setCd(widget.plotDegree),child:const Text('Plot Degree'))),
        ]),
        const Text('हर Chakra page पर वही Plot photo रहेगा और Chakra उसके ऊपर overlay होगा।',textAlign:TextAlign.center,style:TextStyle(fontSize:12))
      ])))
    ]));
  Widget pageView(File chakra)=>LayoutBuilder(builder:(c,b){
    final w=b.maxWidth;
    return SingleChildScrollView(padding:const EdgeInsets.all(10),child:Column(children:[
      SizedBox(width:w,height:w*1.05,child:Stack(children:[
        Positioned.fill(child:Image.file(widget.plot,fit:BoxFit.contain)),
        Positioned.fill(child:CustomPaint(painter:BPainter(widget.points))),
        Center(child:Transform.rotate(angle:cd*math.pi/180,child:Opacity(opacity:.78,child:Image.file(chakra,width:w*.84,height:w*.84,fit:BoxFit.contain)))),
        Positioned(top:6,left:6,child:Container(padding:const EdgeInsets.all(6),color:Colors.white.withOpacity(.88),child:Text('Plot ${widget.plotDegree.toStringAsFixed(1)}° | Chakra ${cd.toStringAsFixed(1)}°',style:const TextStyle(fontWeight:FontWeight.bold))))
      ]))
    ]));
  });
}
