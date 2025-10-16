import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ペットスキルシミュレーター',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'NotoSansJP'),
      home: SimulatorScreen(),
    );
  }
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  int unwantedSkills = 2;
  int simulationCount = 10000;
  bool isSimulating = false;
  Map<int, SimulationResult> results = {};

  final int totalSkills = 9;
  final Map<int, int> levelCosts = {30: 169000, 60: 169000 + 817500, 90: 169000 + 817500 + 1267500};
  final double refundRate = 0.9;
  final int targetPets = 1;

  final Map<int, int> skillsAtLevel = {30: 2, 60: 3, 90: 4};

  String formatWithK(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ペットスキルシミュレーター'), backgroundColor: Colors.blue.shade700),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildParameterCard(),
              SizedBox(height: 16),
              _buildSimulateButton(),
              SizedBox(height: 16),
              if (results.isNotEmpty) ...[
                _buildResultCard(30),
                SizedBox(height: 16),
                _buildResultCard(60),
                SizedBox(height: 16),
                _buildResultCard(90),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterCard() {
    int wantedSkills = totalSkills - unwantedSkills;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('設定パラメータ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            Row(
              children: [
                Text('ハズレスキル数: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: unwantedSkills.toDouble(),
                    min: 2.0,
                    max: 7.0,
                    divisions: 5,
                    label: unwantedSkills.toString(),
                    onChanged: (value) {
                      setState(() {
                        unwantedSkills = value.round();
                      });
                    },
                  ),
                ),
                Text('$unwantedSkills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('欲しいスキル数: $wantedSkills種', style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),

            Row(
              children: [
                Text('シミュレーション回数: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: simulationCount.toDouble(),
                    min: 1000.0,
                    max: 50000.0,
                    divisions: 49,
                    label: simulationCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        simulationCount = (value / 1000).round() * 1000;
                      });
                    },
                  ),
                ),
                Text('$simulationCount', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSimulating ? null : _runSimulation,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
        child: isSimulating
            ? CircularProgressIndicator(color: Colors.white)
            : Text('シミュレーション実行（LV30/60/90すべて）', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildResultCard(int level) {
    final result = results[level];
    if (result == null) return Container();

    return Card(
      elevation: 4,
      color: level == 30 ? Colors.blue.shade50 : (level == 60 ? Colors.green.shade50 : Colors.orange.shade50),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LV$level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  'コスト: ${formatWithK(levelCosts[level]!.toDouble())}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildResultRow('全成功確率', '${result.successRate.toStringAsFixed(2)}%'),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            _buildResultRow('必要ペット数 (平均)', '${result.averagePetsUsed.toStringAsFixed(1)}体', isMain: true),
            _buildResultRow('ペット数範囲', '${result.minPetsUsed}～${result.maxPetsUsed}体'),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            _buildResultRow('平均総コスト (1体)', formatWithK(result.averageTotalCost), isMain: true),
            _buildResultRow('中央値', formatWithK(result.medianCost)),
            _buildResultRow('範囲', '${formatWithK(result.minCost)} ～ ${formatWithK(result.maxCost)}'),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            _buildResultRow('無駄ビスケット', formatWithK(result.wastedBiscuits), isWarning: true),
            _buildResultRow('無駄率', '${result.wasteRate.toStringAsFixed(1)}%', isWarning: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isMain = false, bool isWarning = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: isMain ? 15 : 13, fontWeight: isMain ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 15 : 13,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
              color: isWarning ? Colors.red.shade700 : (isMain ? Colors.blue.shade900 : null),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSimulation() async {
    setState(() {
      isSimulating = true;
      results.clear();
    });

    for (int level in [30, 60, 90]) {
      final simulator = PetSkillSimulator(
        totalSkills: totalSkills,
        unwantedSkills: unwantedSkills,
        targetLevel: level,
        levelCosts: levelCosts,
        refundRate: refundRate,
        targetPets: targetPets,
        skillsAtLevel: skillsAtLevel,
      );

      final simulationResult = await simulator.runSimulation(simulationCount);

      setState(() {
        results[level] = simulationResult;
      });
    }

    setState(() {
      isSimulating = false;
    });
  }
}

class PetSkillSimulator {
  final int totalSkills;
  final int unwantedSkills;
  final int targetLevel;
  final Map<int, int> levelCosts;
  final double refundRate;
  final int targetPets;
  final Map<int, int> skillsAtLevel;

  late final int wantedSkills;
  late final Random random;

  PetSkillSimulator({
    required this.totalSkills,
    required this.unwantedSkills,
    required this.targetLevel,
    required this.levelCosts,
    required this.refundRate,
    required this.targetPets,
    required this.skillsAtLevel,
  }) {
    wantedSkills = totalSkills - unwantedSkills;
    random = Random();
  }

  Future<SimulationResult> runSimulation(int simulationCount) async {
    List<double> totalCosts = [];
    List<double> wastedAmounts = [];
    List<int> attemptsList = [];
    List<int> petsUsedList = [];

    for (int sim = 0; sim < simulationCount; sim++) {
      double totalCost = 0.0;
      double totalWasted = 0.0;
      int totalAttempts = 0;
      int totalPetsUsed = 0;

      for (int pet = 0; pet < targetPets; pet++) {
        final petResult = _simulateOnePet();
        totalCost += petResult.cost;
        totalWasted += petResult.wasted;
        totalAttempts += petResult.attempts;
        totalPetsUsed += petResult.petsUsed;
      }

      totalCosts.add(totalCost);
      wastedAmounts.add(totalWasted);
      attemptsList.add(totalAttempts);
      petsUsedList.add(totalPetsUsed);
    }

    totalCosts.sort();
    wastedAmounts.sort();
    petsUsedList.sort();

    double averageCost = totalCosts.reduce((a, b) => a + b) / totalCosts.length;
    double averageWasted = wastedAmounts.reduce((a, b) => a + b) / wastedAmounts.length;
    double averageAttempts = attemptsList.reduce((a, b) => a + b) / attemptsList.length / targetPets;
    double averagePetsUsed = petsUsedList.reduce((a, b) => a + b) / petsUsedList.length;
    double medianCost = totalCosts[totalCosts.length ~/ 2];
    double minCost = totalCosts.first;
    double maxCost = totalCosts.last;
    int minPetsUsed = petsUsedList.first;
    int maxPetsUsed = petsUsedList.last;

    double theoreticalCost = _calculateTheoreticalCost();
    double successProb = _calculateSuccessProbability();

    return SimulationResult(
      targetLevel: targetLevel,
      unwantedSkills: unwantedSkills,
      successRate: successProb * 100,
      averageTotalCost: averageCost,
      medianCost: medianCost,
      minCost: minCost,
      maxCost: maxCost,
      wastedBiscuits: averageWasted,
      wasteRate: (averageWasted / averageCost) * 100,
      theoreticalCost: theoreticalCost,
      averageAttempts: averageAttempts,
      averagePetsUsed: averagePetsUsed,
      minPetsUsed: minPetsUsed,
      maxPetsUsed: maxPetsUsed,
    );
  }

  PetResult _simulateOnePet() {
    int attempts = 0;
    int petsUsed = 0;
    double wasted = 0.0;
    int levelCost = levelCosts[targetLevel]!;

    while (true) {
      attempts++;
      petsUsed++;

      List<int> availableSkills = List.generate(totalSkills, (i) => i);
      availableSkills.removeAt(random.nextInt(wantedSkills));

      bool failed = false;
      int skillsNeeded = skillsAtLevel[targetLevel]! - 1;

      for (int i = 0; i < skillsNeeded; i++) {
        int selectedIndex = random.nextInt(availableSkills.length);
        int selectedSkill = availableSkills[selectedIndex];

        if (selectedSkill >= wantedSkills) {
          failed = true;
          break;
        }

        availableSkills.removeAt(selectedIndex);
      }

      if (!failed) {
        double totalCost = levelCost + wasted;
        return PetResult(cost: totalCost, wasted: wasted, attempts: attempts, petsUsed: petsUsed);
      } else {
        wasted += levelCost * (1.0 - refundRate);
      }
    }
  }

  double _calculateSuccessProbability() {
    int drawCount = skillsAtLevel[targetLevel]! - 1;

    double prob = 1.0;
    int remainingWanted = wantedSkills;
    int remainingTotal = totalSkills;

    for (int i = 0; i < drawCount; i++) {
      prob *= remainingWanted / remainingTotal;
      remainingWanted--;
      remainingTotal--;
    }

    return prob;
  }

  double _calculateTheoreticalCost() {
    double successProb = _calculateSuccessProbability();
    if (successProb <= 0) return 0;
    double expectedAttempts = 1.0 / successProb;
    double expectedFails = expectedAttempts - 1.0;
    int levelCost = levelCosts[targetLevel]!;
    double netFailCost = levelCost * (1.0 - refundRate);
    double expectedCostPerPet = expectedFails * netFailCost + levelCost;
    return expectedCostPerPet * targetPets;
  }
}

class PetResult {
  final double cost;
  final double wasted;
  final int attempts;
  final int petsUsed;

  PetResult({required this.cost, required this.wasted, required this.attempts, required this.petsUsed});
}

class SimulationResult {
  final int targetLevel;
  final int unwantedSkills;
  final double successRate;
  final double averageTotalCost;
  final double medianCost;
  final double minCost;
  final double maxCost;
  final double wastedBiscuits;
  final double wasteRate;
  final double theoreticalCost;
  final double averageAttempts;
  final double averagePetsUsed;
  final int minPetsUsed;
  final int maxPetsUsed;

  SimulationResult({
    required this.targetLevel,
    required this.unwantedSkills,
    required this.successRate,
    required this.averageTotalCost,
    required this.medianCost,
    required this.minCost,
    required this.maxCost,
    required this.wastedBiscuits,
    required this.wasteRate,
    required this.theoreticalCost,
    required this.averageAttempts,
    required this.averagePetsUsed,
    required this.minPetsUsed,
    required this.maxPetsUsed,
  });
}
