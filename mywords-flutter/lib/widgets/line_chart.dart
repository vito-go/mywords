import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';

class LineValue {
  late final String tip; //图例提示文字
  late final double barWidth; //图例提示文字
  late final List<FlSpot> flSpots;

  LineValue(this.tip, this.flSpots, this.barWidth);
}

class ChartLineData {
  late final String title;
  late final String subTitle;
  late final String xName;
  late final String yName;
  late final bool dotDataShow;
  late final Map<String, dynamic> xTitleMap;

  // late final Map<String, dynamic> xTitleIndexMap;
  late final Map<String, dynamic> yTitleMap;
  late final double baselineY;
  late final double? minY;
  late final double? maxY;

  late final List<LineValue> lineValues;

  ChartLineData.fromJson(Map<String, dynamic> m) {
    title = m['title'] ?? '';
    subTitle = m['subTitle'] ?? '';
    xName = m['xName'] ?? '';
    yName = m['yName'] ?? '';
    baselineY = double.parse(m['baselineY'].toString());
    minY = double.tryParse(m['minY'].toString());
    maxY = double.tryParse(m['maxY'].toString());
    dotDataShow = m['dotDataShow'] ?? true;
    xTitleMap = m['xTitleMap'] ?? {};
    yTitleMap = m['yTitleMap'] ?? {};
    // xTitleIndexMap = m['xTitleIndexMap'] ?? {};

    List<LineValue> list = [];
    for (var element in m['lineValues'] ?? []) {
      List<FlSpot> listSpots = [];
      for (var ele in element['flSpots'] ?? []) {
        // type 'int' is not a subtype of type 'double' in type cast
        listSpots.add(FlSpot((double.tryParse(ele[0].toString()) ?? 0),
            (double.tryParse(ele[1].toString()) ?? 0)));
      }
      list.add(LineValue(element["tip"].toString(), listSpots,
          double.parse((element["barWidth"] ?? "2.0").toString())));
    }
    lineValues = list;
  }
}

class LineChartSample extends StatefulWidget {
  const LineChartSample(
      {super.key, required this.chartLineData, required this.isCurved});

  final ChartLineData chartLineData;
  final bool isCurved;

  @override
  State<StatefulWidget> createState() => LineChartSampleState();
}

class LineChartSampleState extends State<LineChartSample> {
  late final ChartLineData chartLineData = widget.chartLineData;

  @override
  void initState() {
    super.initState();
  }

  Widget buildLegend({
    required Color color,
    required tip,
    required isSquare,
    double size = 16,
    Color textColor = Colors.white,
  }) {
    final tipHide = prefs.getTipHideWithLevel(tip);
    List<Widget> children = <Widget>[
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
          color: color,
        ),
      ),
      const SizedBox(
        width: 4,
      ),
      Text(
        tip,
        style: TextStyle(
          fontSize: 16,
          fontWeight: tipHide ? FontWeight.normal : FontWeight.bold,
          color: tipHide ? Colors.grey : textColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(
        width: 10,
      ),
    ];

    return InkWell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
        onTap: () {
          prefs.setTipHideWithLevel(tip, !prefs.getTipHideWithLevel(tip));
          setState(() {});
        });
  }

  List<Widget> getLegends() {
    List<Widget> children = [];
    for (var i = 0; i < chartLineData.lineValues.length; i++) {
      if (chartLineData.lineValues[i].tip == "") {
        continue;
      }
      if (chartLineData.lineValues[i].flSpots.isEmpty) {
        continue;
      }
      final w = buildLegend(
          color: lineColors[i],
          tip: chartLineData.lineValues[i].tip,
          isSquare: true);
      children.add(w);
    }
    return children;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final legends = getLegends();
    final List<Widget> children = [];
    if (chartLineData.title != "") {
      children.add(const SizedBox(height: 12));
      final w = Text(chartLineData.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center);
      children.add(w);
    }
    if (chartLineData.subTitle != "") {
      children.add(const SizedBox(height: 12));
      children.add(Text(
        chartLineData.subTitle,
        style: const TextStyle(
          color: Color(0xff827daa),
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ));
    }
    if (legends.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(Wrap(
        alignment: WrapAlignment.end,
        runSpacing: 0,
        spacing: 20,
        children: legends,
      ));
    }
    children.add(const SizedBox(height: 10));
    children.add(Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 48, left: 6, bottom: 10, top: 26),
        child: _LineChart(
          data: chartLineData,
          isCurved: widget.isCurved,
        ),
      ),
    ));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(0)),
        gradient: LinearGradient(
          colors: [
            Color(0xff2c274c),
            Color(0xff46426c),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

// lineColors的长度必须大于 [lines]
const List<Color> lineColors = [
  Color(0xff4af699),
  Colors.purpleAccent,
  Colors.orange,
  Colors.yellow,
  Colors.tealAccent,
];

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor = Colors.white70,
  });

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
          color: color,
        ),
      ),
      const SizedBox(
        width: 4,
      ),
      Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(
        width: 10,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _LineChart extends StatelessWidget {
  final ChartLineData data;
  final bool isCurved;

  const _LineChart({required this.data, required this.isCurved});

  final double barWidth = 1; // 根据lines 动态调整

  @override
  Widget build(BuildContext context) {
    return LineChart(sampleData1);
  }

  List<ShowingTooltipIndicators> get showingTooltipIndicators {
    return [];
  }

  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData(),
        baselineY: data.baselineY,
        // minX: 0,
        // maxX: 240,
        maxY: data.maxY,
        minY: data.minY,
        showingTooltipIndicators: showingTooltipIndicators,
      );

  /// Cover Default implementation for [LineTouchTooltipData.getTooltipItems].
  List<LineTooltipItem> getTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      final textStyle = TextStyle(
          color: touchedSpot.bar.gradient?.colors.first ??
              touchedSpot.bar.color ??
              Colors.blueGrey);
      String y = touchedSpot.y.toInt().toString();
      String x = data.xTitleMap[touchedSpot.x.toInt().toString()] ??
          touchedSpot.x.toInt().toString();
      if (data.xName != "" && data.yName != "") {
        return LineTooltipItem(
            "${data.xName}: $x\n${data.yName}: $y", textStyle,
            textAlign: TextAlign.start);
      }
      return LineTooltipItem("$x: $y", textStyle, textAlign: TextAlign.start);
    }).toList();
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.75),
          getTooltipItems: getTooltipItems,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
      );

  AxisTitles get leftTitles {
    final sideTitles = SideTitles(
        reservedSize: 42,
        showTitles: true,
        getTitlesWidget: (double value, TitleMeta meta) {
          final valueDouble = value;
          const style = TextStyle(color: Colors.white);
          if (valueDouble.toInt() != valueDouble) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: const Text(""),
            );
          }
          return SideTitleWidget(
            axisSide: meta.axisSide,
            // child: Text(meta.formattedValue, style: style),
            child: Text("${valueDouble.toInt()}", style: style),
          );
        });
    return AxisTitles(sideTitles: sideTitles);
  }

  // Y轴
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white);
    String valueText = "";
    if (value == 0.0) {
      valueText = "0";
    } else {
      valueText = data.yTitleMap[value.toInt().toString()] ?? '';
    }
    Text text = Text(valueText, style: style, textAlign: TextAlign.center);
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  SideTitles get leftSideTitles => SideTitles(
      getTitlesWidget: leftTitleWidgets, showTitles: true, reservedSize: 44);

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: bottomTitles,
        rightTitles: rightTitles,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: leftTitles,
      );

  List<LineChartBarData> lineBarsData() {
    List<LineChartBarData> result = [];
    for (var i = 0; i < data.lineValues.length; i++) {
      result.add(lineChartBarData1(
        color: lineColors[i],
        barWidth: data.lineValues[i].barWidth,
        spots: data.lineValues[i].flSpots,
        isCurved: isCurved,
        show: !prefs.getTipHideWithLevel(data.lineValues[i].tip),
      ));
    }
    return result;
  }

  Widget rightTitleWidgets(double value, TitleMeta meta) {
    return const Text("");
  }

  AxisTitles get rightTitles => AxisTitles(
      sideTitles: SideTitles(
          getTitlesWidget: rightTitleWidgets,
          showTitles: false,
          reservedSize: 22));

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff72719b));
    Widget text;
    // web 版本必须用.toInt()才能和linux版本保持一致. linux: value 带一位小数 web 的value不带小数位
    final t = data.xTitleMap[value.toInt().toString()] ?? "";
    text = Text(t, style: style, textAlign: TextAlign.start);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      angle: -0.75,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: text,
      ),
    );
  }

  AxisTitles get bottomTitles => AxisTitles(
          sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 72,
        interval: 2,
        getTitlesWidget: bottomTitleWidgets,
      ));

  FlGridData get gridData => FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (double value) {
        if (value.toStringAsFixed(2) == data.baselineY.toStringAsFixed(2)) {
          return const FlLine(
              strokeWidth: 1.5, color: Colors.blue, dashArray: [10, 0]);
        }
        return defaultGridLine(value);
      });

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xff4e4965), width: 4),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  LineChartBarData lineChartBarData1({
    required Color color,
    required List<FlSpot> spots,
    required double barWidth,
    bool isCurved = true,
    bool show = true,
  }) {
    return LineChartBarData(
      isCurved: isCurved,
      color: color,
      barWidth: barWidth,
      show: show,
      isStrokeCapRound: true,
      dotData: FlDotData(
          checkToShowDot: (FlSpot spot, LineChartBarData barData) {
            return true;
          },
          show: true),
      belowBarData: BarAreaData(show: false),
      aboveBarData: BarAreaData(show: false),
      spots: spots,
    );
  }
}
