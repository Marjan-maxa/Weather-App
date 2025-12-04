import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class WeatherAppScreen extends StatefulWidget {
  const WeatherAppScreen({super.key});

  @override
  State<WeatherAppScreen> createState() => _WeatherAppScreenState();
}

class _WeatherAppScreenState extends State<WeatherAppScreen> {

  final _cityController=TextEditingController(text: 'Dhaka');
  bool isloading=false;
  String? _error;
  String ? _resolvedCity;
  double? tempC;
  int ? _wCode;
  double ? _windkmph;
  String ? _wText;

  double ? _hi,_lo;




  Future<({String city, String country,double lat,double lng})>geoCoding(String city)
  async {
    final url=Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=en&format=json');
    final response=await http.get(url);
    print(response.body);

    if(response.statusCode!=200) throw Exception('Geo Coding Error${response.statusCode}');
    final decodedData= jsonDecode(response.body) as Map<String ,dynamic>;
    final result=decodedData['results'] as List<dynamic>;
    if(result==null || result.isEmpty) throw Exception('City not found');

    final m=result.first as Map<String,dynamic>;
    final rName=m['name'] as String;
    final rLat=m['latitude'] as double;
    final rLong=m['longitude'] as double;
    final rCountry=m['country'] as String;
   // print('$rName, $rLat  $rLong $rCountry');

    return(city:rName, country:rCountry,lat:rLat,lng:rLong);

  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    geoCoding('Dhaka');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
            Colors.blueAccent,
            Colors.blue,
            Colors.lightBlueAccent,
            Colors.white
          ])
        ),

        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(8),
            children: [
              const SizedBox(height: 15,),
              Row(
                children: [
                  const SizedBox(height: 10,),
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                        color: Colors.white
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter your City(eg:Dhaka)',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(color: Colors.black)
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: Colors.black)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: Colors.white)
                        )
                      ),
                    ),
                  ),
                  const SizedBox(width: 3,),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black
                    ),
                      onPressed: (){}, child: Text('Search'))
                ],
              ),
              const SizedBox(height: 15,),
              Column(
                children: [
                  Text('My Locatioon',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white),),
                  Text('Current Locatioon',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.white)),
                  Text('37°C',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 100,color: Colors.white)),
                  Text('Cloud',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white))
                ],
              ),
              const SizedBox(height: 16,),
              Card(

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Wind is 20 kmps'),
                ),
              ),
              const SizedBox(height: 16,),

              Card(
                child: Column(
                  children: [
                    Text('2:00'),
                  Icon(Icons.cloud),
                    Text('37°C'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
