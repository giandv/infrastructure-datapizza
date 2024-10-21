Presupposti per la parte Terraform:
- Aver installato Terraform, su Mac è possibile lanciare il comando brew

  brew install terraform

- Avere un progetto GCP (es. datapizza-1234) cui è associato un account con fatturazione.

- Prima di intraprendere il lancio delle operazioni Terraform da locale è necessario eseguire il comando:

  export $(cat ./state-data-pizza.env | xargs)

- Creazione di un account di servizio con impersonificazione, per adempiere a questo punto è possibile seguire i semplici passi visionabili in questo link: https://drive.google.com/file/d/1cJFk-hZs-k8rRhKTfCgaHAUZongx_gds/view.

  Il service account di tipo delegate creato dal precedente video supporremo sia terraform@datapizza-1234.iam.gserviceaccount.com e sia salvato al percorso /tmp/terraform-impersonate.json

- Supponiamo di aver registrato un dominio su Cloud Domains della piattaforma GCP
  - Tale opererazione si può effettuare con Terraform ma per mantenere lo sviluppo separata dalla proprietà lo si presuppone già predisposto da GUI, in alternativa la risorsa Terraform sarebbe stata la google_clouddomains_registration.
  Il valore del nostro dominio sarà contenuto nella variabile DNS [valore datapizza.tech], mentre il sotto-dominio equivale al valore [jobs] - variabile SUB_DNS. Esso si aggiungerà infatti come record associato al DNS di cui sopra.

- Primi step intrapresi nella parte Terraform:
  - registrazione della google_dns_managed_zone associata al dominio cui ci si riferiva al punto precedente
  - creazione della cloud function
  - creazione delle rete virtuale che raggruppa le componenti della nostra architettura (eccezion fatta per la cloud function)
  - realizzazione di un gruppo di VM su cui girerà Docker per l'orchestrazione dei micro-servizi (file data_pizza.tf)

  Tra questi files uno su cui preme effettuare delle precisazioni è sicuramente il file data_pizza.tf.

  PRECISAZIONI:
    - Su di esso, per agevolarci ed avere dice riutilizzabile con Terraform si è utilizzato il modulo terraform-google-lb-http, link GitHub: https://github.com/terraform-google-modules/terraform-google-lb-http/tree/master.
    Dove si può scorgere che per rispondere al requisito "La web app deve essere distribuita globalmente e accessibile solo in https" si sono utilizzati i parametri:
      - managed_ssl_certificate_domains [delegando a GCP la gestione dei certificati SSL]
      - https_redirect, per il redirect in maniera da essere accessibile solo in HTTPS

    - Inoltre in questo file si cerca di rispondere anche al requisito
      "La web app deve essere capace di sopportare carichi elevati (fino a 10 mila utenti connessi contemporaneamente che fanno operazioni) ma nei momenti scarichi deve cercare di ottimizzare le risorse per evitare billing troppo elevati."
      Configurando per l'appunto uno scaling delle VM utilizzando la risorsa google_compute_autoscaler, che parte con una configurazione di tre VM per scalare fino ad un massimo di 30 VM con un target abbastanza basso 0.25 che ne facilita lo scaling all'aumentare delle richieste.

    - Degno di nota è anche l'argomento
        session_affinity = "CLIENT_IP" contenuto in module.backends
      che impedisce il redirect su di altre VM a causa del bilanciatore di carico.

  Successivamente al file data_pizza.tf si rimanda l'attenzione ai files:
  - sql.tf
  - function.tf

  Nel file sql.tf si trova la definizione dell'istanza cloud sql con la definizione di un database e di un utenza associata.
  -> "Il Database deve avere una replica." -> non è stato inserito nella parte Docker per aver una sola replica, all'interno della VPC ma non nelle macchine VM in maniera tale da non essere soggetta anche a politiche di scaling.

  Non ultimo il file function.tf, non soggetto a vincoli della VPC e per questo motivo facilmente riutilizzabile per altri scopi. Il bucket che storicizza il sorgente della funzione serverless non è soggetto a performance ragion per cui si è optato per averla nella location US che prevede costi minori.
