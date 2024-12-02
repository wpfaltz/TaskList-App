import 'dart:io';

int main() {
    String? input = stdin.readLineSync();
    if (input == "") {print("Entrada vazia!");}
    else{
      int? intParsed = int.tryParse(input!);
      if (intParsed != null) {
        if (intParsed < 0) {print("Número negativo!");}
        else {
          String checagemPrimo = checaPrimo(intParsed);
          print(checagemPrimo);
        }
      }
      else {
        double? float = double.tryParse(input);
        if (float != null) {print("Não é inteiro!");}
        else {
          String formatarFloat = input.replaceAll(",", ".");
          double? floatAux = double.tryParse(formatarFloat);
          if (floatAux != null) {print("Formato numérico inválido!");}
          else{print("Não é um número!");}
          }
      }
    }
    return 0;
}

String checaPrimo (int n) {
  String primoStatus = "É primo!";
  if (n == 1) {primoStatus = "Não é primo!";}
  else {
    for (var i = 2; i*i <= n; i++) {
      if (n % i == 0) {primoStatus = "Não é primo!";}
    };
  }
  return primoStatus;
}