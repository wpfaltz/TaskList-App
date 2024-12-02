import 'dart:io';

int main() {
    List<int> numerosPerfeitos = <int>[];
    List<List> divisoresNumerosPerfeitos = <List>[];
    int maiorNumeroAbundante = 0;
    List<int> divisoresMaiorNumeroAbundante = <int>[];
    int somaDivisoresMaiorNumeroAbundante = 0;

    String? input = stdin.readLineSync();
    
    List<String> splitString = input!.split(' ');
    if (splitString.length != 2) {print("Por favor forneça dois números inteiros positivos.");}
    else if (splitString.length == 2) {
        int? numeroInicial = int.tryParse(splitString[0]);
        int? numeroFinal = int.tryParse(splitString[1]);
        if (numeroInicial == null || numeroFinal == null){
            print("Por favor forneça dois números inteiros positivos.");
        }
        else if (numeroInicial > numeroFinal) {
          print("O primeiro número deve ser menor ou igual ao segundo.");
        }
        else if (numeroInicial < 0 || numeroFinal < 0) {
          print("Por favor forneça dois números inteiros positivos.");
        }
        else {
            for (int i = numeroInicial; i <= numeroFinal; i++) {
                List<int> divisores = encontraDivisores(i);
                int somaDivisores = calculaSomaDivisores(divisores);
                if (somaDivisores == i) {
                    numerosPerfeitos.add(i); 
                    divisoresNumerosPerfeitos.add(divisores);
                }
                else if (somaDivisores > i) {
                    if (somaDivisores > somaDivisoresMaiorNumeroAbundante) {
                        maiorNumeroAbundante = i;
                        divisoresMaiorNumeroAbundante = divisores;
                        somaDivisoresMaiorNumeroAbundante = somaDivisores;
                    }
                }
            }

            printarNumerosPerfeitos(numerosPerfeitos, divisoresNumerosPerfeitos, numeroInicial, numeroFinal);
            printarMaiorNumeroAbundante(maiorNumeroAbundante, divisoresMaiorNumeroAbundante, somaDivisoresMaiorNumeroAbundante, numeroInicial, numeroFinal);
        }
    }
    return 0;
}

List<int> encontraDivisores(int n) {
    List<int> divisores = <int>[];
    for (int i = 1; i < n; i++) {
        if (n % i == 0) {divisores.add(i);}
    }
    return divisores;
}

int calculaSomaDivisores(List<int> divisores) {
    int soma = 0;
    for (int i = 0; i < divisores.length; i++) {
        soma = soma + divisores[i];
    }
    return soma;
}

void printarNumerosPerfeitos(List<int> numerosPerfeitos, List<List> divisoresNumerosPerfeitos, int numeroInicial, int numeroFinal) {
    if (numerosPerfeitos.length == 0) {print("Nenhum número perfeito encontrado na faixa entre $numeroInicial e $numeroFinal.");}
    else {
        for (int i = 0; i < numerosPerfeitos.length; i++) {
            int numeroPerfeito = numerosPerfeitos[i];
            List divisoresNumeroPerfeito = divisoresNumerosPerfeitos[i];
            print("$numeroPerfeito é um número perfeito.");
            print("Fatores: $divisoresNumeroPerfeito");
        }
    }
}

void printarMaiorNumeroAbundante(int maiorNumeroAbundante, List<int> divisoresMaiorNumeroAbundante, int somaDivisoresMaiorNumeroAbundante, int numeroInicial, int numeroFinal) {
    if (maiorNumeroAbundante == 0) {
        print("Nenhum número abundante encontrado na faixa entre $numeroInicial e $numeroFinal.");
    }
    else {
        print("Maior número abundante: $maiorNumeroAbundante");
        print("Fatores: $divisoresMaiorNumeroAbundante");
        print("Soma dos fatores: $somaDivisoresMaiorNumeroAbundante");
    }
}