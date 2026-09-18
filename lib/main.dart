import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main()=>runApp(const App());

class App extends StatelessWidget{
 const App({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(
   debugShowCheckedModeBanner:false,title:'Vastu Plot + Chakra',
   theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff2f6b3a))),
   home:const Home());
}

class BP{Offset p; BP(this.p);}

class Home extends StatefulWidget{const Home({super.key}); @override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 final picker=ImagePicker(); File? plot; final pts=<BP>[]; final chakras=<File>[];
 double degree=0; bool delete=false;

 Future<void> pickPlot()async{final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:95);if(x!=null)setState((){plot=File(x.path);pts.clear();});}
 Future<void> pickChakras()async{final xs=await picker.pickMultiImage(imageQuality:95);if(xs.isNotEmpty)setState(()=>chakras.addAll(xs.map((x)=>File(x.path))));}
 @override Widget build(BuildContext c)=>Scaffold(
   appBar:AppBar(title:const Text('Vastu Plot + Chakra')),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    Text('1. Plot Photo',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    FilledButton.icon(onPressed:pickPlot,icon:const Icon(Icons.photo_library),label:const Text('Plot Photo Select करें')),
    const SizedBox(height:14),
    Text('2. Plot Boundary',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:5),
    const Text('4 नहीं — जितने चाहें red dots लगाएँ और finger से drag करके सही जगह करें।'),
    Row(children:[
      Expanded(child:FilledButton.tonal(onPressed:()=>setState(()=>delete=false),child:const Text('Add / Move'))),
      const SizedBox(width:8),
      Expanded(child:OutlinedButton(onPressed:()=>setState(()=>delete=true),child:const Text('Delete')))]),
    const SizedBox(height:8),
    if(plot==null)Container(height:300,alignment:Alignment.center,decoration:BoxDecoration(border:Border.all(),borderRadius:BorderRadius.circular(12)),child:const Text('Plot photo select करें'))
    else PlotEditor(image:plot!,points:pts,deleteMode:delete,onChanged:()=>setState((){})),
    const SizedBox(height:14),
    Text('3. Plot / North Degree',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    TextField(key:ValueKey(degree),keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),
      decoration:const InputDecoration(labelText:'Plot Degree',suffixText:'°',border:OutlineInputBorder()),
      controller:TextEditingController(text:degree.toStringAsFixed(1)),
      onChanged:(v){final n=double.tryParse(v);if(n!=null)setState(()=>degree=((n%360)+360)%360);}),
    const SizedBox(height:14),
    Text('4. Chakra Photos',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    FilledButton.icon(onPressed:pickChakras,icon:const Icon(Icons.add_photo_alternate),label:const Text('Mobile Folder से Chakra Photos चुनें')),
    Text('${chakras.length} Chakra photos selected'),
    const SizedBox(height:10),
    if(plot!=null&&chakras.isNotEmpty)FilledButton.icon(
      onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Viewer(plot:plot!,points:pts,chakras:chakras,plotDegree:degree))),
      icon:const Icon(Icons.layers),label:const Text('Plot + Chakra साथ में देखें'))
   ]));
}

class PlotEditor extends StatelessWidget{
 final File image;final List<BP> points;final bool deleteMode;final VoidCallback onChanged;
 const PlotEditor({super.key,required this.image,required this.points,required this.deleteMode,required this.onChanged});
 @override Widget build(BuildContext c)=>LayoutBuilder(builder:(c,bc){
   final w=bc.maxWidth,h=w*.72;
   return GestureDetector(onTapDown:(d){if(!deleteMode) {points.add(BP(d.localPosition));onChanged();}},
    child:SizedBox(width:w,height:h,child:Stack(children:[
     Positioned.fill(child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(image,fit:BoxFit.fill))),
     Positioned.fill(child:CustomPaint(painter:BPainter(points))),
     for(int i=0;i<points.length;i++)Positioned(left:points[i].p.dx-14,top:points[i].p.dy-14,
       child:GestureDetector(
        onPanUpdate:(d){if(!deleteMode){points[i].p+=d.delta;onChanged();}},
        onLongPress:(){if(deleteMode){points.removeAt(i);onChanged();}},
        child:Container(width:28,height:28,alignment:Alignment.center,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),
          child:Text('${i+1}',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold)))))])));
 });
}
class BPainter extends CustomPainter{
 final List<BP> p;BPainter(this.p);
 @override void paint(Canvas c,Size s){if(p.length<2)return;final q=Paint()..color=Colors.green..strokeWidth=3..style=PaintingStyle.stroke;final x=Path()..moveTo(p[0].p.dx,p[0].p.dy);for(final a in p.skip(1))x.lineTo(a.p.dx,a.p.dy);if(p.length>2)x.close();c.drawPath(x,q);}
 @override bool shouldRepaint(covariant BPainter old)=>true;
}

class Viewer extends StatefulWidget{
 final File plot;final List<BP> points;final List<File> chakras;final double plotDegree;
 const Viewer({super.key,required this.plot,required this.points,required this.chakras,required this.plotDegree});
 @override State<Viewer> createState()=>_ViewerState();
}
class _ViewerState extends State<Viewer>{
 late final PageController pc;int page=0;late double cd;
 @override void initState(){super.initState();pc=PageController();cd=widget.plotDegree;}
 @override void dispose(){pc.dispose();super.dispose();}
 void setCd(double v)=>setState(()=>cd=((v%360)+360)%360);
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
     Expanded(child:FilledButton(onPressed:()=>setCd(widget.plotDegree),child:const Text('Plot Degree')))]),
    const Text('Plot degree से Chakra की initial setting होगी; फिर Chakra को अलग से manually rotate कर सकते हैं.',textAlign:TextAlign.center,style:TextStyle(fontSize:12))
   ])))
  ]));
 Widget pageView(File chakra)=>LayoutBuilder(builder:(c,b){
  final w=b.maxWidth;
  return SingleChildScrollView(padding:const EdgeInsets.all(10),child:Column(children:[
   SizedBox(width:w,height:w*1.05,child:Stack(children:[
    Positioned.fill(child:Image.file(widget.plot,fit:BoxFit.contain)),
    Positioned.fill(child:CustomPaint(painter:BPainter(widget.points))),
    Center(child:Transform.rotate(angle:cd*math.pi/180,child:Opacity(opacity:.78,child:Image.file(chakra,width:w*.82,height:w*.82,fit:BoxFit.contain)))),
    Positioned(top:6,left:6,child:Container(padding:const EdgeInsets.all(6),color:Colors.white.withOpacity(.88),child:Text('Plot ${widget.plotDegree.toStringAsFixed(1)}° | Chakra ${cd.toStringAsFixed(1)}°',style:const TextStyle(fontWeight:FontWeight.bold))))
   ]))
  ]));
 }
}
