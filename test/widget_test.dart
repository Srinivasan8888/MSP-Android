    import 'package:flutter/material.dart';

    void main() {
      runApp(MyApp());
    }

    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final Size screenSize = MediaQuery.of(context).size;
                // Calculate item dimensions to fill half the screen width and height
                final double itemWidth = screenSize.width / 2;
                // Adjust for potential top padding (status bar) if not in SafeArea
                final double itemHeight = (screenSize.height - MediaQuery.of(context).padding.top) / 2; 

                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: itemWidth / itemHeight, // Calculate aspect ratio
                  children: <Widget>[
                    Container(color: Colors.red),
                    Container(color: Colors.blue),
                    Container(color: Colors.green),
                    Container(color: Colors.yellow),
                  ],
                );
              },
            ),
          ),
        );
      }
    }