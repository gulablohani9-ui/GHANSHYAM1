
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const VastuChakraApp());

class VastuChakraApp extends StatelessWidget {
  const VastuChakraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vastu Plot + Chakra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6B3A)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class PlotPoint {
  Offset p;
  PlotPoint(this.p);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? plotImage;
  final List<PlotPoint> points = [];
  final List<File> chakras = [];
  bool addMode = true;

  Future<void> pickPlot() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x != null) {
      setState(() {
        plotImage = File(x.path);
        points.clear();
      });
    }
  }

  Future<void> pickChakras() async {
    // image_picker supports multi-select on Android/iOS through pickMultiImage.
    final xs = await _picker.pickMultiImage(imageQuality: 95);
    if (xs.isNotEmpty) {
      setState(() => chakras.addAll(xs.map((x) => File(x.path))));
    }
  }

  void resetPoints() => setState(() => points.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vastu Plot + Chakra'),
        actions: [
          if (chakras.isNotEmpty)
            IconButton(
              tooltip: 'Chakra pages',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChakraPages(plotImage: plotImage, chakras: chakras),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: pickPlot,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Plot Photo Select करें'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: pickChakras,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Mobile Folder से Chakra Photos चुनें'),
          ),
          const SizedBox(height: 8),
          Text(
            '${chakras.length} chakra photo selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => setState(() => addMode = true),
                  child: const Text('Add / Move Dots'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => addMode = false),
                  child: const Text('Delete Dot'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: resetPoints,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Dots'),
          ),
          const SizedBox(height: 10),
          Text(
            'Boundary points: ${points.length}  •  4 से ज्यादा points भी लगा सकते हैं',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (plotImage == null)
            Container(
              height: 320,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('पहले plot photo select करें'),
            )
          else
            PlotEditor(
              image: plotImage!,
              points: points,
              addMode: addMode,
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 16),
          if (plotImage != null && chakras.isNotEmpty)
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChakraPages(plotImage: plotImage, chakras: chakras),
                ),
              ),
              icon: const Icon(Icons.slideshow),
              label: const Text('Plot के साथ Chakra Pages देखें'),
            ),
        ],
      ),
    );
  }
}

class PlotEditor extends StatelessWidget {
  final File image;
  final List<PlotPoint> points;
  final bool addMode;
  final VoidCallback onChanged;

  const PlotEditor({
    super.key,
    required this.image,
    required this.points,
    required this.addMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxWidth * 0.72);
        return GestureDetector(
          onTapDown: (d) {
            if (!addMode) return;
            final p = d.localPosition;
            if (p.dx >= 0 && p.dy >= 0 && p.dx <= size.width && p.dy <= size.height) {
              points.add(PlotPoint(p));
              onChanged();
            }
          },
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image, fit: BoxFit.fill),
                ),
                CustomPaint(
                  painter: BoundaryPainter(points),
                ),
                for (int i = 0; i < points.length; i++)
                  Positioned(
                    left: points[i].p.dx - 13,
                    top: points[i].p.dy - 13,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        points[i].p += d.delta;
                        onChanged();
                      },
                      onLongPress: () {
                        if (!addMode) {
                          points.removeAt(i);
                          onChanged();
                        }
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BoundaryPainter extends CustomPainter {
  final List<PlotPoint> points;
  BoundaryPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final line = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.p.dx, points.first.p.dy);
    for (final pt in points.skip(1)) {
      path.lineTo(pt.p.dx, pt.p.dy);
    }
    if (points.length >= 3) path.close();
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) => true;
}

class ChakraPages extends StatefulWidget {
  final File? plotImage;
  final List<File> chakras;
  const ChakraPages({super.key, required this.plotImage, required this.chakras});

  @override
  State<ChakraPages> createState() => _ChakraPagesState();
}

class _ChakraPagesState extends State<ChakraPages> {
  late final PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plot + Chakra Pages')),
      body: PageView.builder(
        controller: controller,
        itemCount: widget.chakras.length,
        itemBuilder: (_, i) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Page ${i + 1} / ${widget.chakras.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (widget.plotImage != null)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(widget.plotImage!, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(widget.chakras[i], fit: BoxFit.contain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
