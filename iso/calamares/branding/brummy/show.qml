/* Slideshow simples enquanto instala. Troque os textos à vontade. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation
    Timer { interval: 6000; running: true; repeat: true; onTriggered: presentation.goToNextSlide(); }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            color: "#ffffff"
            font.pixelSize: 22
            text: "Brummy Linux\n\nArch + Hyprland, com cara própria.\nRápido como tiling, clicável como sempre foi."
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            color: "#ffffff"
            font.pixelSize: 22
            text: "SUPER+Espaço abre o Spotlight.\nSUPER+E os arquivos. SUPER+Q o terminal.\n\nEsqueceu? Rode: brummy help"
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            color: "#ffffff"
            font.pixelSize: 22
            text: "Tudo o que você vê aqui está versionado\nnum repo que é seu para mexer."
        }
    }
}
