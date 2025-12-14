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

  //Current

  double? tempC;
  int ? _wCode;
  double ? _windkmph;
  String ? _wText;
String? _country;
  double ? _hi,_lo;

List<_Hourly>_hourly=[];




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

  // -------------------------weather API----------------------------------


  Future<void> fetch(String city)async {
    setState(() {
      isloading=true;
      _error=null;
    });

    try{
      final getGeo=await geoCoding(city);
      final url=Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=${getGeo.lat}&longitude=${getGeo.lng}'
          '&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset'
          '&hourly=temperature_2m,weather_code,wind_speed_10m'
          '&current=temperature_2m,weather_code,wind_speed_10m'
          '&timezone=auto');
      
      final response=await http.get(url);
      if(response.statusCode!=200)throw Exception('Forecast error${response.statusCode}');
      final decodedData=jsonDecode(response.body) as Map<String ,dynamic>;

      // Current

      final current=(decodedData['current'] as Map?)??{};
      final tempc=((current['temperature_2m']??0)as num).toDouble();
      final wCode=(current['weather_code']as num ?)?.toInt();
      final windkps=((current['wind_speed_10m']?? 0)as num).toDouble();


      final hourly=(decodedData['hourly'] as Map<String,dynamic>);
      final htime=List<String>.from(hourly['time'] as List);
      final htemp=List<num>.from(hourly['temperature_2m'] as List);
      final hcode=List<num>.from(hourly['weather_code'] as List);

      final outHourly=<_Hourly>[];
      for(int i=0;i<htime.length;i++){
        outHourly.add(_Hourly(
            time: DateTime.parse(htime[i]),
            temp: (htemp[i]).toDouble(),
            code: hcode[i].toInt())
        );
      }


      setState(() {
        tempC=tempc;
        _wCode=wCode;
        _windkmph=windkps;
        _resolvedCity=getGeo.city;
        _country=getGeo.country;
        _hourly=outHourly;

      });


      print(response.body);
    }catch(e){
      _error=e.toString();
    }finally{
      setState(() {
        isloading=false;
      });
    }
  }







  //  https://api.open-meteo.com/v1/forecast?latitude=23.7104&longitude=90.40744&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weather_code&hourly=temperature_2m,weather_code&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetch('Dhaka');
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
               isloading? LinearProgressIndicator():SizedBox(),
              const SizedBox(height: 15,),
              Row(
                children: [
                  const SizedBox(height: 10,),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
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
                      onPressed:isloading?null:()=>fetch(_cityController.text), child: Text('Search'))
                ],
              ),
              const SizedBox(height: 15,),
              Column(
                children: [
                  Text(_country==null?"My Location":" $_country",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.white),),
                  Text(_resolvedCity??'My Location',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white)),
                  Text(tempC.toString(),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 100,color: Colors.white)),
                  Text(_wCode.toString(),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white))
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

class _Hourly {
  final DateTime time;
  final double temp;
  final int code;

  _Hourly({required this.time,required this.temp,required this.code,} );

}

