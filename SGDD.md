# **Ponto Cego**

## SGDD by Carlos Brito

## **História**

Manuela vive trancada em uma torre sombria de onde ninguém nunca escapou. Certa noite, aproveitando uma falha na vigilância, ela decide fugir pelos corredores, driblando os guardas que patrulham o local, até alcançar o portão e desaparecer na escuridão.

## **Jogo**

Começa o jogo com a tela de loading exibindo uma tela de menu principal \[música: tema de abertura, tom tenso\] com os botões "Jogar", "Fases" e "Sair" \[som: clicar\]. Clicando em "Jogar" é exibida uma tela de seleção de fase, mostrando as áreas da torre já desbloqueadas.

Ao entrar numa fase, a câmera segue a personagem em uma visão top-down doa ambiente (corredor/cozinha/jardim). A jogadora controla Manuela, que pode se mover pelo mapa. Os guardas patrulham rotas fixas e possuem um cone de visão desenhado à frente deles. Sempre que Manuela entra no cone \[som: alerta\!\], uma barra de suspeita na interface começa a encher gradualmente; se ela sair do campo de visão a tempo, a barra esvazia, mas se enche por completo o guarda a captura e é fim de jogo.

Para ajudar na fuga, Manuela pode coletar power-ups espalhados pelo cenário: a poção de invisibilidade, que, ao ser consumida  \[som: beber poção\], ativa um temporizador curto durante o qual Manuela não pode ser detectada, e o saco de vento, usado para apagar as velas \[som: assoprar\], que reduz drasticamente o alcance do cone de visão dos guardas na área.

Cada fase também apresenta sub-objetivos que devem ser cumpridos antes de alcançar a saída, como encontrar uma chave e abrir uma porta trancada \[som: abrir porta\]. Um indicador de objetivos na interface mostra o progresso desses sub-objetivos.

Se um guarda captura Manuela, é exibida a tela de derrota \[música: derrota\] com a opção de reiniciar a fase. Se ela alcança a saída, é exibida a tela de vitória \[música: vitória\], liberando a próxima fase no mapa.

## **Arte**

* Tela de Loading;  
* Tela de Menu Principal;  
* Tela de Seleção de Fase;  
* Personagem Manuela: parada, andando, bebendo poção;  
* Guardas: parado, patrulhando, em alerta;  
* Cone de visão do guarda (indicador visual, normal e reduzido);  
* Tileset: corredores da torre;  
* Tileset: cozinha;  
* Tileset: jardim externo;  
* Interface: barra de suspeita/alerta;  
* Interface: ícone de power-up ativo (poção, saco de vento);  
* Interface: indicador de sub-objetivos;  
* Tela Final: vitória;  
* Tela Final: derrota;  
* Botões: Jogar, Fases, Sair, Reiniciar;  
* HUD: barra de suspeita, ícones de power-up, contador de objetivos;

## **Audio**

* Música da tela de abertura;  
* Música de exploração (por área);  
* Música de vitória;  
* Música de derrota;  
* Som: clicar;  
* Som: abrir porta;  
* Som: beber poção (invisibilidade);  
* Som: assoprar;  
* Som: alerta do guarda;  
* Som: captura;  
* Som: alerta;

## **Programação**

* Loading e transições de tela;  
* Movimento da personagem;  
* Câmera seguindo a personagem;  
* Patrulha dos guardas (rotas fixas);  
* Cone de visão do guarda (detecção por ângulo/distância);  
* Barra de suspeita (incremento/decremento gradual);  
* Power-up: poção de invisibilidade (temporizador, imunidade à detecção);  
* Power-up: apagar velas (reduz alcance do cone de visão);  
* Sistema de sub-objetivos por fase (flags: chave/porta, etc.);  
* Detecção de vitória (chegar à saída com objetivos cumpridos);  
* Detecção de derrota (capturada pelo guarda);  
* Reinício de fase;