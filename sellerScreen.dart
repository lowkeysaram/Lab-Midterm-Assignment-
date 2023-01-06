// ignore: file_names
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ndialog/ndialog.dart';
import '../config.dart';
import '../product.dart';
import '../shared/mainmenu.dart';
import '../user.dart';
import 'detailscreen.dart';
import 'loginScreen.dart';
import 'newProductScreen.dart';
import 'registrationScreen.dart';

class SellerScreen extends StatefulWidget {
  final User user;
  const SellerScreen({super.key, required this.user});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  var _lat, _lng;
  late Position _position;
  List<Product> productList = <Product>[];
  String titleCenter = "Loading...";
  var placemarks;
  final df = DateFormat('dd/MM/yyyy hh:mm a');
  late double screenHeight, screenWidth, resWidth;
  int rowCount = 2;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    productList = [];
    print("dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 600) {
      resWidth = screenWidth;
      rowCount = 2;
    } else {
      resWidth = screenWidth * 0.75;
      rowCount = 3;
    }
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(title: const Text("Seller"), actions: [
            IconButton(
                onPressed: _registrationForm,
                icon: const Icon(Icons.app_registration)),
            IconButton(onPressed: _loginForm, icon: const Icon(Icons.login)),
            PopupMenuButton(
                // add icon, by default "3 dot" icon
                // icon: Icon(Icons.book)
                itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Text("New Product"),
                  //on tap dosen't works
                ),
                const PopupMenuItem<int>(
                  value: 1,
                  child: Text("My Order"),
                ),
              ];
            }, onSelected: (value) {
              if (value == 0) {
                _gotoNewProduct();
                print("My account menu is selected.");
              } else if (value == 1) {
                print("Settings menu is selected.");
              } else if (value == 2) {
                print("Logout menu is selected.");
              }
            }),
          ]),
          body: productList.isEmpty
              ? Center(
                  child: Text(titleCenter,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)))
              //can put loading at here: progressbar/animation/etc --> selagi data kosong
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Your current products/services (${productList.length} found)",
                        style: (const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    //deleteproduct
                    Expanded(
                      child: GridView.count(
                        //gridview: container to the widget
                        crossAxisCount: rowCount,
                        children: List.generate(productList.length, (index) {
                          return Card(
                            elevation: 8,
                            child: InkWell(
                              onTap: () {
                                _showDetails(index);
                              },
                              onLongPress: () {
                                _deleteDialog(index);
                              },
                              child: Column(children: [
                                // Text(productList[index].productName.toString()),
                                // Text("RM${productList[index].productPrice}"),
                                const SizedBox(
                                  height: 8,
                                ),
                                Flexible(
                                  flex: 6,
                                  child: CachedNetworkImage(
                                    //save image in local db --> only load for first time
                                    width: resWidth / 2,
                                    fit: BoxFit.cover,
                                    imageUrl:
                                        "${Config.SERVER}/assets/productimages/${productList[index].productId}.png",
                                    placeholder: (context, url) =>
                                        const LinearProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                                Flexible(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            truncateString(
                                                productList[index]
                                                    .productName
                                                    .toString(),
                                                15),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              "RM ${double.parse(productList[index].productPrice.toString()).toStringAsFixed(2)}"),
                                          // Text(df.format(DateTime.parse(
                                          //     productList[index]
                                          //         .productDate
                                          //         .toString()))),
                                        ],
                                      ),
                                    ))
                              ]),
                            ),
                          );
                        }),
                      ),
                    )
                  ],
                ),
          drawer: MainMenuWidget(user: widget.user)),
    );
  }

  void _registrationForm() {
    Navigator.push(context,
        MaterialPageRoute(builder: (content) => const RegistrationScreen()));
  }

  void _loginForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (content) => const LoginScreen()));
  }

  Future<void> _gotoNewProduct() async {
    if (widget.user.id == "0") {
      Fluttertoast.showToast(
          msg: "Please login/register",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 14.0);
      return;
    }
    ProgressDialog progressDialog = ProgressDialog(
      context,
      blur: 10,
      message: const Text("Searching your current location"),
      title: null,
    );
    progressDialog.show();
    if (await _checkPermissionGetLoc()) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (content) => NewProductScreen(
                    position: _position,
                    user: widget.user,
                    placemarks: placemarks,
                  )));
      _loadProducts();
    } else {
      Fluttertoast.showToast(
          msg: "Please allow the app to access the location",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 14.0);
    }
  }

  Future<bool> _checkPermissionGetLoc() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
            msg: "Please allow the app to access the location",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            fontSize: 14.0);
        Geolocator.openLocationSettings();
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Please allow the app to access the location",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 14.0);
      Geolocator.openLocationSettings();
      return false;
    }
    _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    try {
      placemarks = await placemarkFromCoordinates(
          _position.latitude, _position.longitude);
    } catch (e) {
      Fluttertoast.showToast(
          msg:
              "Error in fixing your location. Make sure internet connection is available and try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 14.0);
      return false;
    }
    return true;
  }

  // void _loadProducts() {
  //   if (widget.user.id == "0") {
  //     setState(() {
  //       titleCenter =
  //           "Unregistered User, \nplease register before use the service";
  //     });
  //     // Fluttertoast.showToast(
  //     //     msg: "Please register an account first",
  //     //     toastLength: Toast.LENGTH_SHORT,
  //     //     gravity: ToastGravity.BOTTOM,
  //     //     timeInSecForIosWeb: 1,
  //     //     fontSize: 14.0);
  //     // return;
  //   }
  //   http
  //       .get(
  //     Uri.parse(
  //         //simple query --> get
  //         //security query -->post
  //         "${Config.SERVER}/loadsellerproduct.php?user_id=${widget.user.id}"),
  //   )
  //       .then((response) {
  //     if (response.statusCode == 200) {
  //       var jsondata = jsonDecode(response.body);
  //       if (jsondata['status'] == 'success') {
  //         var extractData = jsondata['data'];
  //         if (extractData['products'] != null) {
  //           productList = [];
  //           extractData['products'].forEach((v) {
  //             productList.add(Product.fromJson(v));
  //             productList[0].productName;
  //           });
  //           titleCenter = "Found";
  //         } else {
  //           titleCenter = "No Product Available";
  //           productList.clear();
  //         }
  //       }
  //     }
  //   });
  // }
  _loadProducts() {
    if (widget.user.id == "0") {
      setState(() {
        titleCenter = "Unregistered User, Please register before use";
      });
      return;
    }
    http
        .get(Uri.parse(
            "${Config.SERVER}/php/loadsellerproduct.php?user_id=${widget.user.id}"))
        .then((response) {
      if (response.statusCode == 200) {
        //if statuscode OK
        var jsondata =
            jsonDecode(response.body); //decode response body to jsondata array
        if (jsondata['status'] == 'success') {
          //check if status data array is success
          var extractdata = jsondata['data']; //extract data from jsondata array
          if (extractdata['products'] != null) {
            //check if  array object is not null
            productList = <Product>[]; //complete the array object definition
            extractdata['products'].forEach((v) {
              //traverse products array list and add to the list object array productList
              productList.add(Product.fromJson(
                  v)); //add each product array to the list object array productList
              print(productList[0].productName);
            });
            titleCenter = "Found";
          } else {
            titleCenter =
                "No Product Available"; //if no data returned show title center
            productList.clear();
          }
        } else {
          titleCenter = "No Product Available";
        }
      } else {
        titleCenter = "No Product Available"; //status code other than 200
        productList.clear(); //clear productList array
      }
      setState(() {}); //refresh UI
    });
  }

  Future<void> _showDetails(int index) async {
    //Product product1 = Product.fromJson(productList[index].toJson());
    Product product = Product.fromJson(productList[index].toJson());
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (content) => DetailsScreen(
                  product: product,
                  user: widget.user,
                )));
    _loadProducts();
  }

  String truncateString(String str, int size) {
    //string long --> put truncate (...)
    if (str.length > size) {
      str = str.substring(0, size);
      return "$str...";
    } else {
      return str;
    }
  }

  void _deleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text(
            "Delete ${truncateString(productList[index].productName.toString(), 15)}",
            style: TextStyle(),
          ),
          content: const Text("Are you sure?", style: TextStyle()),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Yes",
                style: TextStyle(),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteProduct(index);
              },
            ),
            TextButton(
              child: const Text(
                "No",
                style: TextStyle(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int index) {
    try {
      http.post(Uri.parse("${Config.SERVER}/php/delete_product.php"), body: {
        "product_id": productList[index].productId,
      }).then((response) {
        var data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['status'] == "success") {
          Fluttertoast.showToast(
              msg: "Success",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              fontSize: 14.0);
          _loadProducts();
          return;
        } else {
          Fluttertoast.showToast(
              msg: "Failed",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              fontSize: 14.0);
          return;
        }

        //print(response.body);
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
