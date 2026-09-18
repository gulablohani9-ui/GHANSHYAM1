import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() => runApp(const VastuApp());

class VastuApp extends StatelessWidget {
  const VastuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vastu Plot + Chakra',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2f6b3a)),
        ),
        home: const HomePage(),
      );
}

class BoundaryPoint {
  BoundaryPoint(this.position);
  Offset position;
}

class ChakraTransform {
  ChakraTransform({this.angle = 0, this.scale = .84, this.offset = Offset.zero});
  double angle;
  double scale;
  Offset offset;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController name = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController degree = TextEditingController(text: '0');
  final List<BoundaryPoint> points = <BoundaryPoint>[];
  final List<File> chakras = <File>[];
  final List<ChakraTransform> transforms = <ChakraTransform>[];
  File? plot;
  String? folder;
  bool deleteMode = false;
  double plotDegree = 0;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    mobile.dispose();
    degree.dispose();
    super.dispose();
  }

  double normalize(double value) {
    final double r = value % 360;
    return r < 0 ? r + 360 : r;
  }

  void msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> pickPlot() async {
    final XFile? x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null || !mounted) return;
    setState(() {
      plot = File(x.path);
      points.clear();
    });
  }

  Future<void> chooseFolder() async {
    final String? selected = await FilePicker.platform.getDirectoryPath(dialogTitle: 'CHKRA folder select करें');
    if (selected == null) return;
    setState(() => folder = selected);
    await refreshChakras();
  }

  Future<void> refreshChakras() async {
    final String? selectedFolder = folder;
    if (selectedFolder == null) return;
    final Directory dir = Directory(selectedFolder);
    if (!await dir.exists()) {
      msg('CHKRA folder नहीं मिला।');
      return;
    }
    const Set<String> ext = <String>{'.png', '.jpg', '.jpeg', '.webp'};
    final List<File> found = <File>[];
    await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
      if (entity is File && ext.contains(path.extension(entity.path).toLowerCase())) found.add(entity);
    }
    found.sort((File a, File b) => path.basename(a.path).toLowerCase().compareTo(path.basename(b.path).toLowerCase()));
    if (!mounted) return;
    setState(() {
      chakras
        ..clear()
        ..addAll(found);
      while (transforms.length < chakras.length) transforms.add(ChakraTransform(angle: plotDegree));
      if (transforms.length > chakras.length) transforms.removeRange(chakras.length, transforms.length);
    });
    msg('${found.length} Chakra image मिलीं।');
  }

  void setDegree(String value) {
    final double? n = double.tryParse(value);
    if (n == null) return;
    setState(() {
      plotDegree = normalize(n);
      for (final ChakraTransform t in transforms) t.angle = plotDegree;
    });
  }

  Future<void> openViewer() async {
    if (plot == null || chakras.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChakraViewer(
        plot: plot!,
        points: points,
        chakras: chakras,
        transforms: transforms,
        plotDegree: plotDegree,
      ),
    ));
    if (mounted) setState(() {});
  }

  Future<void> makePdf() async {
    if (plot == null || chakras.isEmpty) {
      msg('Plot और कम से कम 1 Chakra जरूरी है।');
      return;
    }
    final pw.Document doc = pw.Document();
    final Uint8List plotBytes = await plot!.readAsBytes();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Vastu Plot + Chakra Report', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Client Name: ${name.text.trim()}'),
          pw.Text('Address: ${address.text.trim()}'),
          pw.Text('Mobile: ${mobile.text.trim()}'),
          pw.SizedBox(height: 10),
          pw.Text('Plot / North Degree: ${plotDegree.toStringAsFixed(1)}°'),
          pw.Text('Total Chakra Pages: ${chakras.length}'),
          pw.SizedBox(height: 14),
          pw.Expanded(child: pw.Center(child: pw.Image(pw.MemoryImage(plotBytes), fit: pw.BoxFit.contain))),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Ghanshyam Lohani', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    ));

    for (int i = 0; i < chakras.length; i++) {
      final Uint8List chakraBytes = await chakras[i].readAsBytes();
      final ChakraTransform t = transforms[i];
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (_) => pw.Column(
          children: <pw.Widget>[
            pw.Text('Chakra ${i + 1}  •  ${path.basename(chakras[i].path)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Expanded(
              child: pw.Stack(children: <pw.Widget>[
                pw.Positioned.fill(child: pw.Image(pw.MemoryImage(plotBytes), fit: pw.BoxFit.contain)),
                pw.Center(
                  child: pw.Transform.translate(
                    offset: PdfPoint(t.offset.dx, t.offset.dy),
                    child: pw.Transform.rotate(
                      angle: t.angle * math.pi / 180,
                      child: pw.Opacity(
                        opacity: .78,
                        child: pw.Image(pw.MemoryImage(chakraBytes), width: 360 * t.scale, height: 360 * t.scale, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Plot Degree: ${plotDegree.toStringAsFixed(1)}°   |   Chakra Degree: ${t.angle.toStringAsFixed(1)}°', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.Text('Ghanshyam Lohani', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ));
    }

    final List<int> bytes = await doc.save();
    Directory target = Directory('/storage/emulated/0/Download');
    if (!await target.exists()) target = await Directory.systemTemp.createTemp('vastu_report_');
    final File output = File(path.join(target.path, 'Vastu_Plot_Chakra_Report.pdf'));
    await output.writeAsBytes(bytes, flush: true);
    msg('PDF तैयार: ${output.path}');
  }

  Widget title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Vastu Plot + Chakra')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            title('1. Client Details'),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            title('2. Plot Photo'),
            FilledButton.icon(onPressed: pickPlot, icon: const Icon(Icons.photo_library), label: const Text('Plot Photo Select करें')),
            const SizedBox(height: 12),
            title('3. Plot Boundary'),
            const Text('जितने चाहें red dots लगाएँ। Dot को drag करें। Delete mode में dot पर long-press करें।'),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Expanded(child: FilledButton.tonal(onPressed: () => setState(() => deleteMode = false), child: const Text('Add / Move'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => setState(() => deleteMode = true), child: const Text('Delete'))),
            ]),
            const SizedBox(height: 8),
            if (plot == null)
              Container(height: 280, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)), child: const Text('Plot photo select करें'))
            else
              PlotEditor(image: plot!, points: points, deleteMode: deleteMode, onChanged: () => setState(() {})),
            const SizedBox(height: 14),
            title('4. Plot / North Degree'),
            TextField(
              controller: degree,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              onChanged: setDegree,
              decoration: const InputDecoration(labelText: 'Plot Degree', suffixText: '°', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            title('5. CHKRA Folder'),
            const Text('Mobile में CHKRA folder में PNG/JPG/JPEG/WebP images रखें। पहली बार folder select करें, फिर Refresh दबाएँ।'),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: chooseFolder, icon: const Icon(Icons.folder_open), label: const Text('CHKRA Folder Select करें')),
            if (folder != null) Text('Folder: $folder', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: refreshChakras, icon: const Icon(Icons.refresh), label: const Text('Refresh CHKRA Folder')),
            Text('${chakras.length} Chakra images मिलीं'),
            const SizedBox(height: 16),
            if (plot != null && chakras.isNotEmpty) ...<Widget>[
              FilledButton.icon(onPressed: openViewer, icon: const Icon(Icons.layers), label: const Text('Plot के ऊपर Chakra देखें / Rotate / Zoom')),
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: makePdf, icon: const Icon(Icons.picture_as_pdf), label: Text('${chakras.length + 1} Page PDF बनाएं')),
            ],
          ],
        ),
      );
}

class PlotEditor extends StatelessWidget {
  const PlotEditor({super.key, required this.image, required this.points, required this.deleteMode, required this.onChanged});
  final File image;
  final List<BoundaryPoint> points;
  final bool deleteMode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
        final double width = box.maxWidth;
        final double height = width * .72;
        return GestureDetector(
          onTapDown: (TapDownDetails d) {
            if (!deleteMode) {
              points.add(BoundaryPoint(d.localPosition));
              onChanged();
            }
          },
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(children: <Widget>[
              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image, fit: BoxFit.fill))),
              Positioned.fill(child: CustomPaint(painter: BoundaryPainter(points))),
              for (int i = 0; i < points.length; i++)
                Positioned(
                  left: points[i].position.dx - 14,
                  top: points[i].position.dy - 14,
                  child: GestureDetector(
                    onPanUpdate: (DragUpdateDetails d) {
                      if (!deleteMode) {
                        points[i].position += d.delta;
                        onChanged();
                      }
                    },
                    onLongPress: () {
                      if (deleteMode) {
                        points.removeAt(i);
                        onChanged();
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ]),
          ),
        );
      });
}

class BoundaryPainter extends CustomPainter {
  const BoundaryPainter(this.points);
  final List<BoundaryPoint> points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final Paint paint = Paint()..color = Colors.green..strokeWidth = 3..style = PaintingStyle.stroke;
    final Path p = Path()..moveTo(points.first.position.dx, points.first.position.dy);
    for (final BoundaryPoint point in points.skip(1)) p.lineTo(point.position.dx, point.position.dy);
    if (points.length > 2) p.close();
    canvas.drawPath(p, paint);
  }
  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) => true;
}

class ChakraViewer extends StatefulWidget {
  const ChakraViewer({super.key, required this.plot, required this.points, required this.chakras, required this.transforms, required this.plotDegree});
  final File plot;
  final List<BoundaryPoint> points;
  final List<File> chakras;
  final List<ChakraTransform> transforms;
  final double plotDegree;
  @override
  State<ChakraViewer> createState() => _ChakraViewerState();
}

class _ChakraViewerState extends State<ChakraViewer> {
  late final PageController controller;
  late final List<double> startAngles;
  late final List<double> startScales;
  int page = 0;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    startAngles = List<double>.filled(widget.chakras.length, 0);
    startScales = List<double>.filled(widget.chakras.length, 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double norm(double value) {
    final double r = value % 360;
    return r < 0 ? r + 360 : r;
  }

  void rotate(double amount) => setState(() => widget.transforms[page].angle = norm(widget.transforms[page].angle + amount));

  void reset() => setState(() {
        final ChakraTransform t = widget.transforms[page];
        t.angle = widget.plotDegree;
        t.scale = .84;
        t.offset = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    final ChakraTransform t = widget.transforms[page];
    return Scaffold(
      appBar: AppBar(title: Text('Plot + Chakra  ${page + 1}/${widget.chakras.length}')),
      body: Column(children: <Widget>[
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: widget.chakras.length,
            onPageChanged: (int i) => setState(() => page = i),
            itemBuilder: (_, int i) => _page(i),
          ),
        ),
        Material(
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(children: <Widget>[
                Row(children: <Widget>[
                  Text('Plot: ${widget.plotDegree.toStringAsFixed(1)}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('Chakra: ${t.angle.toStringAsFixed(1)}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                Slider(min: 0, max: 360, value: t.angle.clamp(0.0, 360.0).toDouble(), onChanged: (double v) => setState(() => t.angle = v)),
                Row(children: <Widget>[
                  Expanded(child: OutlinedButton(onPressed: () => rotate(-1), child: const Text('-1°'))),
                  const SizedBox(width: 6),
                  Expanded(child: OutlinedButton(onPressed: () => rotate(1), child: const Text('+1°'))),
                  const SizedBox(width: 6),
                  Expanded(child: FilledButton(onPressed: reset, child: const Text('Plot Degree'))),
                ]),
                const SizedBox(height: 4),
                const Text('Chakra को finger से move / pinch करके zoom / rotate करें।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _page(int index) {
    final ChakraTransform t = widget.transforms[index];
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
      final double width = box.maxWidth;
      final double height = math.max(220.0, math.min(box.maxHeight - 20.0, width)).toDouble();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              onScaleStart: (_) {
                startAngles[index] = t.angle;
                startScales[index] = t.scale;
              },
              onScaleUpdate: (ScaleUpdateDetails d) {
                setState(() {
                  t.scale = (startScales[index] * d.scale).clamp(.25, 2.5).toDouble();
                  t.angle = norm(startAngles[index] + d.rotation * 180 / math.pi);
                  t.offset += d.focalPointDelta;
                });
              },
              child: Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
                Positioned.fill(child: Image.file(widget.plot, fit: BoxFit.contain)),
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: BoundaryPainter(widget.points)))),
                Center(
                  child: Transform.translate(
                    offset: t.offset,
                    child: Transform.rotate(
                      angle: t.angle * math.pi / 180,
                      child: Opacity(
                        opacity: .78,
                        child: Image.file(widget.chakras[index], width: width * t.scale, height: width * t.scale, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                    color: Colors.white.withOpacity(.88),
                    child: Text('Chakra ${index + 1} | Plot ${widget.plotDegree.toStringAsFixed(1)}° | Chakra ${t.angle.toStringAsFixed(1)}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}
