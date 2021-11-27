import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  late Client httpClient;
  late Web3Client ethClient;
  bool data = false;
  var myData;
  String? trxHash;
  final myAddress = "0x855df0Aa757B8da7c41508ED5Af52CA38bE932Fb";
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client("HTTP://127.0.0.1:7545", httpClient);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    // String contractAddress = "0xc5077CF2D293C10F234A9a416CCB5A2376659536";
    String contractAddress = "0x1a06f1B2f27089FBe5deDC60041e9ce90E4af63A";
    final contract = DeployedContract(ContractAbi.fromJson(abi, "PZCoin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    // EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);
    myData = result[0];
    data = true;
    setState(() {});
    print("lucifer Got Balanced...");
  }

  Future<String> sendCoin(String amount) async {
    var bigAmount = BigInt.parse(amount);
    var response = await submit("buyCoin", [bigAmount]);
    trxHash = response;
    print("lucifer Deposited... trx hash => $trxHash");
    setState(() {});
    return response;
  }

  Future<String> withdrawn(String amount) async {
    var bigAmount = BigInt.parse(amount);
    var response = await submit("sellCoin", [bigAmount]);
    trxHash = response;
    print("lucifer Withdrawn... trx hash => $trxHash");
    setState(() {});
    return response;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    String credHex =
        "548e13db6a64fba984853679edb34bb44fc669eed69a2f3bc0378f238ce7a251";
    EthPrivateKey credEth = EthPrivateKey.fromHex(credHex);
    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credEth,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),chainId: 1337,
        fetchChainIdFromNetworkId: false);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Vx.gray300,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SingleChildScrollView(
            child: ZStack([
              VxBox()
                  .blue600
                  .size(context.screenWidth, context.percentHeight * 30)
                  .make(),
              VStack([
                (context.percentHeight * 10).heightBox,
                "\$PZ Coin".text.xl4.white.bold.center.makeCentered().py16(),
                (context.percentHeight * 5).heightBox,
                VxBox(
                        child: VStack([
                  "Balance".text.gray700.xl2.semiBold.makeCentered(),
                  10.heightBox,
                  data
                      ? "\$$myData".text.bold.xl6.makeCentered().shimmer()
                      : const CircularProgressIndicator().centered(),
                ]))
                    .p16
                    .white
                    .size(context.screenWidth, context.percentHeight * 30)
                    .rounded
                    .make()
                    .p16(),
                30.heightBox,
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: "e.g. 100",
                        labelText: "Enter Amount",
                        labelStyle:
                            TextStyle(fontSize: 24, color: Colors.black),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    obscureText: false,
                    maxLength: 10,
                    maxLines: 1,
                  ),
                ),
                /*SliderWidget(
                    min: 0,
                    max: 100,
                    finalVal: (value) {
                      myAmount = (value * 100).round();
                      print("My Amount ->> $myAmount");
                    }).centered(),*/
                HStack(
                  [
                    FlatButton.icon(
                            onPressed: () => getBalance(myAddress),
                            color: Colors.blue,
                            shape: Vx.roundedSm,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            label: "Refresh".text.white.make())
                        .h(50),
                    FlatButton.icon(
                            onPressed: () => sendCoin(_controller.text),
                            color: Colors.green,
                            shape: Vx.roundedSm,
                            icon: const Icon(
                              Icons.call_made_outlined,
                              color: Colors.white,
                            ),
                            label: "Deposit".text.white.make())
                        .h(50),
                    FlatButton.icon(
                            onPressed: () => withdrawn(_controller.text),
                            color: Colors.red,
                            shape: Vx.roundedSm,
                            icon: const Icon(
                              Icons.call_received_outlined,
                              color: Colors.white,
                            ),
                            label: "Withdraw".text.white.make())
                        .h(50),
                  ],
                  alignment: MainAxisAlignment.spaceAround,
                  axisSize: MainAxisSize.max,
                ).p16(),
                if (trxHash != null) trxHash!.text.black.makeCentered().p16()
              ])
            ]),
          ),
        ));
  }
}
