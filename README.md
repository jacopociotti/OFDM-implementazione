# 📡 Implementazione e Analisi di un Sistema di Trasmissione OFDM

## 🎯 Obiettivo del Progetto
Questo progetto presenta l'implementazione e l'analisi in ambiente MATLAB di una catena completa di trasmissione e ricezione OFDM (Orthogonal Frequency Division Multiplexing). Il focus principale è sulla stima della Risposta in Frequenza del Canale (`H(f)`) tramite l'inserimento di toni pilota, fondamentale per compensare le distorsioni del segnale (fading, multipath) e minimizzare il tasso di errore in ricezione.

## ⚙️ Architettura del Sistema
Il codice simula tutti gli stadi fondamentali di un sistema di comunicazione digitale:

* **Trasmettitore (TX)**: Genera un segnale OFDM su 64 sottoportanti. I dati binari vengono generati casualmente (PN Sequence) e mappati su una costellazione QPSK. Vengono inseriti periodicamente simboli noti (piloti) con valore `p=1+j`. La trasformazione nel dominio del tempo avviene tramite IFFT.
* **Canale**: Viene simulato un canale wireless affetto da fading di Rayleigh (multipath) e rumore additivo gaussiano bianco (AWGN). La propagazione viene modellata matematicamente tramite una convoluzione circolare, che simula implicitamente la presenza di un Prefisso Ciclico (CP).
* **Ricevitore (RX)**: Riporta il segnale nel dominio della frequenza tramite FFT. Estrae i toni pilota, stima la risposta del canale in quei punti specifici ($\hat{H}_{pilota}$) e ricostruisce l'intera banda tramite interpolazione. 
* **Equalizzazione e Decodifica**: Applica un equalizzatore per compensare le alterazioni di fase e ampiezza dividendo il segnale ricevuto per la stima del canale: $\hat{X}[k]=\frac{Y[k]}{\hat{H}[k]}$. Infine, un decisore a soglia Maximum Likelihood recupera i bit originali calcolando il Bit Error Rate (BER).

## 📊 Analisi Sperimentale e Risultati
Sono stati condotti diversi esperimenti per valutare la robustezza del sistema variando i parametri chiave:

* **Metodi di Interpolazione**: È stato effettuato un confronto tra l'interpolazione *Linear* e *Spline Cubica*. Sebbene l'interpolazione lineare introduca degli spigoli e non segua la naturale curvatura del canale, in scenari a bassa selettività garantisce comunque un numero di errori nullo, similmente alla Spline (che modella la curva molto più fedelmente).
* **Densità dei Piloti e Selettività del Canale**:
  * Canale a bassa selettività ($n_{taps}=2$)**: Una spaziatura intermedia ($\Delta p=16$) rappresenta il compromesso ideale tra stima accurata e basso overhead. Una spaziatura troppo stretta ($\Delta p=4$) occupa inutilmente il 26% delle sottoportanti, mentre una troppo larga ($\Delta p=32$) non ricostruisce bene la curva, pur mantenendo spesso zero errori grazie all'equalizzazione.
  * **Canale ad alta selettività ($n_{taps}=10$)**: Aumentando il numero di echi del canale, la risposta in frequenza diventa molto frastagliata. In questo scenario, una spaziatura $\Delta p=16$ fallisce e genera errori in demodulazione. È indispensabile infittire i piloti (es. $\Delta p=4$) per tracciare le rapide fluttuazioni del canale e riportare a zero gli errori.

## 💡 Conclusioni
La simulazione dimostra l'assoluta necessità dell'equalizzazione in canali dispersivi. Soprattutto, evidenzia che non esiste una configurazione "ottima" universale: un sistema OFDM efficiente deve essere in grado di adattare dinamicamente la densità dei piloti (overhead) in base alla severità delle condizioni di propagazione del canale.
