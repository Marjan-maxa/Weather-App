import 'dart:convert';

import 'package:intl/intl.dart';

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

  List<_Daily> _daily = [];



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
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=${getGeo.lat}&longitude=${getGeo.lng}'
            '&daily=temperature_2m_max,temperature_2m_min,weather_code'
            '&hourly=temperature_2m,weather_code,wind_speed_10m'
            '&current=temperature_2m,weather_code,wind_speed_10m'
            '&timezone=auto',
      );


      final response=await http.get(url);
      if(response.statusCode!=200)throw Exception('Forecast error${response.statusCode}');
      final decodedData=jsonDecode(response.body) as Map<String ,dynamic>;

      // -------- DAILY (7 days) --------
      final daily = decodedData['daily'] as Map<String, dynamic>;

      final dates = List<String>.from(daily['time']);
      final maxs = List<num>.from(daily['temperature_2m_max']);
      final mins = List<num>.from(daily['temperature_2m_min']);
      final codes = List<num>.from(daily['weather_code']);

      final outDaily = <_Daily>[];

      for (int i = 0; i < 7; i++) {
        outDaily.add(
          _Daily(
            date: DateTime.parse(dates[i]),
            max: maxs[i].toDouble(),
            min: mins[i].toDouble(),
            code: codes[i].toInt(),
          ),
        );
      }


      // Current

      final current=(decodedData['current'] as Map?)??{};
      final tempc=((current['temperature_2m']??0)as num).toDouble();
      final wCode=(current['weather_code']as num ?)?.toInt();
      final windkps=((current['wind_speed_10m']?? 0)as num).toDouble();


      // hourly


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
        _daily = outDaily;


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

  
  // code  to text
  
  String _codeToText(int? c){
    if(c==null) return "__";
    if(c==0) return "Most Sunny";
    if([1,2,3].contains(c)) return "Partly Cloudy";
    if([45,48].contains(c)) return "Fogy";
    return 'Cloudy';
  }

  IconData _codeToIcon(int? c){
    if(c==null) return Icons.sunny;
    if(c==0) return Icons.sunny_snowing;
    if([1,2,3].contains(c)) return Icons.cloud;
    if([45,48].contains(c)) return Icons.foggy;
    return Icons.cloud_circle;
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
              const SizedBox(height: 20,),
              Row(
                children: [
                  const SizedBox(height: 12,),
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
                        ),
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
                  Text( tempC == null ? '--°C' : "${tempC!.toStringAsFixed(0)}°C",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 100,color: Colors.white)),
                  Text(_codeToText(_wCode),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white))
                ],
              ),
              const SizedBox(height: 16,),
              Card(

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _windkmph == null
                        ? 'Wind -- kmph'
                        : 'Wind ${_windkmph!.toStringAsFixed(1)} kmph',
                  ),

                ),
              ),
              const SizedBox(height: 16,),

              Card(
                child: Column(
                  children: [
                  SizedBox(
                    height:100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hourly.length,
                      separatorBuilder: (_,__)=> SizedBox(width: 13,),
                        itemBuilder: (context,index){
                        final h=_hourly[index];
                        return Column(
                          children: [
                            Text(DateFormat('hh a').format(h.time)),


                            Icon(_codeToIcon(h.code)),
                            Text("${h.temp.toStringAsFixed(0)}°C"),
                          ],
                        );
                    },


                    ),
                  )
                  ],
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-Day Forecast',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ..._daily.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Text(
                                  DateFormat('EEE').format(d.date),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),

                              Icon(
                                _codeToIcon(d.code),
                                size: 18,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: (d.max - d.min) / 15, // dynamic bar
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),
                              Text('${d.min.toStringAsFixed(0)}°'),
                              const SizedBox(width: 6),
                              Text('${d.max.toStringAsFixed(0)}°'),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

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

class _Daily {
  final DateTime date;
  final double max;
  final double min;
  final int code;

  _Daily({
    required this.date,
    required this.max,
    required this.min,
    required this.code,
  });
}


