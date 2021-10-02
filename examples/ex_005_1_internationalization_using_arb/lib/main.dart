import 'package:ex_005_1_internationalization_using_arb/l10n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends TopStatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: i18nRM.locale,
      localeResolutionCallback: i18nRM.localeResolutionCallback,
      localizationsDelegates: i18nRM.localizationsDelegates,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ReactiveStatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  static final _counter = 0.inj();
  @override
  Widget build(BuildContext context) {
    final _i18n = i18nRM.of(context);
    final textStyle = Theme.of(context).textTheme.headline4;
    return Scaffold(
      appBar: AppBar(
        title: Text(_i18n.helloWorld),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => i18nRM.locale = const Locale('en'),
                  child: const Text('English'),
                ),
                ElevatedButton(
                  onPressed: () => i18nRM.locale = const Locale('ar'),
                  child: const Text('arabic'),
                ),
                ElevatedButton(
                  onPressed: () => i18nRM.locale = const Locale('es'),
                  child: const Text('spanish'),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _i18n.welcome('Bob'),
              style: textStyle,
            ),
            const Divider(),
            Text(
              _i18n.genre('male'),
              style: textStyle,
            ),
            Text(
              _i18n.genre('female'),
              style: textStyle,
            ),
            Text(
              _i18n.genre('other'),
              style: textStyle,
            ),
            const Divider(),
            Text(
              _i18n.plural(_counter.state),
              style: textStyle,
            ),
            Text(
              _i18n.formattedNumber(_counter.state * 10000000),
              style: textStyle,
            ),
            Text(
              _i18n.date(DateTime.now()),
              style: textStyle,
            ),
            const Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _counter.state++,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
