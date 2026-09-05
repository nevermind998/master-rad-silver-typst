
= Генерисање инфраструктуре и постављање апликације

== Генерисање Docker конфигурације

 	Генерисање Docker фајлова у Silverа-и функционише на тај начин да имамо четири Dockerfile-a и један compose фајл. Dockerfile-ови иду кроз Jinja2  шаблон, док је compose укуцан као Python string. На слици 6.3.3:1 је приказан како се по сервису од модела дође до Docker фајла 

 

#figure(image("../slike/slika-6.3.3-1.png", width: 90%), caption: [Дијаграм који показује пут од модела до Docker фајла по сервису]) <slika-6-3-3-1>


	Docker фајл у Silverа-и се генеришу по сервисима. Основни шаблон је приказан на слици 6.3.3:2, мењају се само service.name и service.port у зависности за који сервис се генеришу. 

 
#figure(image("../slike/slika-6.3.3-2.png", width: 90%), caption: [Шаблон за прављење Docker фајлова по сервисима]) <slika-6-3-3-2>



== Генерисање Terraform и Kubernetes конфигурације

У оквиру Silvera-e главни део модела за Terraform је написан у aws-depoyment.si и azure-deployment.si фајловима. Унутар ових фајлова је дефинисано како да се направи све што је потребно за AWS/Azure налог, затим регистровање контејнера и Kubernetes кластера, дефинисање базе, начина слања порука, мониторинг и потребан фајл где се чувају скривене битне информације везане за базу и сервисе. Након што се изгенерише апликација добијемо два одвојена фолдера за AWS и Azure, који имају исту структуру. Структура се може видети на слици 6.9:1. 

 
#figure(image("../slike/slika-6.9-1.png", width: 90%), caption: [Структура фолдера за AWS и Azure]) <slika-6.9-1>

	На слици 6.9:2 је описано како тече сам процес генерисања свих фајлова који су неопходни Terraform-у. 
 
#figure(image("../slike/slika-6.9-2.png", width: 90%), caption: [Структура фајлова за Terraform]) <slika-6-9-2>
Што се тиче самог Kubernetes, доста је погодан алат за апликацију која треба да аутоматизује процес пребацивања апликације на облак, јер ако се све постави лепо у старту, нема потребе за додатним интервенцијама и ручним подешавањима. Кључна улога код генерисања Kubernetes игра функција generate_k8s_manifests, која се налази у оквиру kubernetes_generator.py. То је обична Python функција која је приказана на слици 6.3.4:2.

 
#figure(image("../slike/slika-6.3.4-2.png", width: 90%), caption: [Приказ функције generate_k8s_manifest]) <slika-6-3-4-2>

 	
 	Функција generate_k8s_manifests се састоји из три фазе. Прва фаза је припрема, где се инстанцира Jinja2 Environment, друга фаза итерира кроз model.services и за сваки ServiceDef рендерује deployment.j2. Из модела користи само три вредности, а то су име, порт и изведени назив конекционог стринга, резултат ове фазе су 4 манифест фајлова. На крају се  прави заједнички манифести (yaml фајлови) namespace, configMap, secret и ingress. Ови не иду кроз шаблон него су hardcoded Python стрингови, резултат ове фазе су 8 фајлова. Једини фајл који је потребно ручно написати је rabbitmq.yaml. 

У случају саме апликације за обраду поруџбине генерисане уз помоћ Silvera-e прво Terraform направи празан кластер. Kubernetes манифест фајлови га онда попуни изгенерисаним сервисима. Важно је да се напомене Terraform  покреће једном, док се манифест фајлови покреће приликом сваког deploy. Укратко, Docker све спакује, Terraform прави место где ће радити, а  Kubernetes покреће. За микросервисној архитектури, где постоји велики број независних сервиса, Terraform и Kubernetes доста поједностављују управљање системом. Terraform омогућава поновљиво креирање истих окружења (development, testing, production), док је Kubernetes обезбеђено поуздано извршавање сервиса и динамичко прилагођавање оптерећењу. Управо из ових разлога Terraform и Kubernetes су циљне технологије које се користе за аутоматизацију самог процеса пребацивања апликације на cloude платформе која се генерише коришћењем Silvera-e. ЈСД може поједноставнити сложеност ових технологија тако што корисник описује архитектуру система на вишем нивоу, док се конкретне Terraform и Kubernetes конфигурације генеришу аутоматски.
 
== Проширење Silvera-е подршком за пребацивање апликације и тестирање на Azure платформи

Azure платформа је једно од најраспрострањенијих окружења у облаку, који се користи за развој и извршавање микросервисних апликација. Нуди велики број сервиса који омогућавају скалабилност, високу доступност и једноставно управљање ресурсима. Да би интеграција Silvera-е са Azure платформом била могућа модел треба да се прошити да поред генерисања изворног кода, садржи и информације неопходне за аутоматско креирање конфигурација за пребацивање  и извршавање апликације у облаку. 


=== Мотивација за проширење
	
Потребе савременог софтверског инжењерства захтевају да апликација буде подржана у облаку, поготово ако је реч о микросервисној апликацији. Употребом Silvera-е могуће је да се моделује микросервисна архитектура и да се одради аутоматско генерисање изворног кода. Аутоматизовано постављање у облаку, тестирање и управљање животним циклусом апликације није подржано тим основним циклусом у Silvera-и, па се ту јавила потреба за проширењем. У пракси, процес пребацивања на облачно окружења често захтева да се ручно конфигурише инфраструктуре, дефинишу сервиси, мрежна подешавања и параметар окружења. 

Главна мотивација је да се смањује количина ручног рада и да се упрости процес постављања микросервисне апликације. Из тих разлога јавила се потреба да се што већи део животног циклуса развоја софтвера подржи у оквиру Silvera-е. Проширењем Silvera-е тако да се генеришу неопходни артефаката за пребацивање на Azure платформи, би у великој мери била смањена количина ручног рада и поједностављује процес пребацивања микросервисне апликације. Омогућава аутоматизовано тестирање успешно пребачених сервиса, чиме се обезбеђује да генерисана апликација не само да буде исправно креирана, већ и функционално проверена након постављања.

=== Проширење метамодела и синтаксе

 	Проширење Silvera-е захтева да се дода одређена подршка код прављења самих модела. Та подршка је заправо коришћење метакласе Plugin. Користи се као врста декларације највишег нивоа, равноправна  са већ постојећим декларацијама као што су domain, service, event и остали.  На слици 6.10.2:1 се може видети на који начин је Plugin додат у самој декларацији. Да би се користио Plugin додатаку потребно је за почетак да се дефинише идентитет. Дефинисање идентитета је заправо одређивање назива, верзије и описа. Након тога потребно је написати циљну платформу (target) која је у овом случају Azure. Затим је потребно да се одредити и врста (kind), да ли је у питању deployment или testing. Врста се у овом случају назива још и дискриминатором, јер од ње зависи који ће се ток даље преузети. У конкретном апликацији када се изабере да је kind = deployment, тада се одабере ток који креира семантички модел које омогућавају  пребацибање апликације на Azure.

 
#figure(image("../slike/slika-6.10.2-1.png", width: 90%), caption: [Дефинисање Plugin у коду]) <slika-6-10-2-1>

На слици 6.10.2:2 су приказане семантички модел DeploymentTarget који омогућава пребацивање апликације на Azure. Oва класа се даље грана на ServiceDeployment, она носи CPU, memory, min/max-replicas, назив апликације и референцира сервис из језгра. Логички сервис претвара у ресурс који се може покренути. Следећа метакласа је ContainerAppsEnv додавањем ове метакласе метамодел добија две алтернативне платформе, а изведено својство uses_container_apps бира између њих. То је у ужем смислу је подршка за Azure. Ingress је адреса сервиса и састоји се од порт и тачног излази с адресама. Без тога испоручен систем нема објављену адресу, па се не може ни позвати ни проверити. Како се то види у синтакси је на слици 6.10.2:2.


 
#figure(image("../slike/slika-6.10.2-2.png", width: 90%), caption: [Синтаксни приказ метамодела]) <slika-6-10-2-2>


На слици  6.10.2:3 је приказано како се то види у коду

 
#figure(image("../slike/slika-6.10.2-3.png", width: 90%), caption: [Приказ метамодела за деполјмент у коду]) <slika-6-10-2-3>

 	Закључак је да проширење додаје језгру језика тачно једну метакласу Plugin, а сву платформску сложеност смешта иза њеног дискриминатора. Тиме основни Silvera модел остаје платформски независан, док пребацивање апликације и тестирање постају прворазредни, проверљиви делови модела уместо пратећих скрипти које се тихо разилазе са системом који описују.


=== Генерисање Azure конфигурације и пребацивање сервиса на Azure

Да би било омогућено да се Azure конфигурација изгенерише уз помоћ Silvera-е, потребно је да постоји .si фајл за почетак. У конкретном случају ове апликације назван је azure-deployment.si и представља Silvera модел, од кога ће настати све оно то је потребно за пребацивање апликације на Azure.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу azure-deployment.si  су дефинисане следеће ствари resource-group, container-registry, container-apps-environment, database, messaging, key-vault, service-deployments, ingress,monitoring. 

Како би пребацивање на Azure било могућ потребно је да постоји претходно креиран налог, који има одређене претплате које подржавају покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату Azure за студенте   и добила 100 долара бесплатног кредита који могу да користим. Када постоји креиран налог са активном претплатом потребно је да се одради команда az acr login, након ње docker compose build. На слици 6.10.3:1 се види како то све изгледа након успешног пребацивања апликације на Azure-у. Све ово је смештено у оквиру order-tracking-rg ресурс групе.

 
#figure(image("../slike/slika-6.10.3-1.png", width: 90%), caption: [Ресурси order-tracking-rg групе]) <slika-6-10-3-1>
Поставка за Kubernetes сервисе је на слици 6.10.3:2. 
#figure(image("../slike/slika-6.10.3-2.png", width: 90%), caption: [Kubernetes сервис]) <slika-6-10-3-2>


Укупан трошак ових сервиса за последњих три месеца је приказан на слици 6.10.3:3.
 
#figure(image("../slike/slika-6.10.3-3.png", width: 90%), caption: [Преглед трошкова за три месеца]) <slika-6-10-3-3>
Сви сервиси су смештени у оквиру Kubernetes сервиса order-tracking-aks, јер је то био једноставнији начин како би се покретање свих сервиса уклопило у претплату за Azurе налог који користим. Преглед тога видљив је на слици 6.10.3:4.

 
#figure(image("../slike/slika-6.10.3-4.png", width: 90%), caption: [Ресурси order-tracking-aks групе]) <slika-6-10-3-4>

=== Тестирање имплементираног решења на Azure платоформи

Јако је битно да постоји одређен начин провере рада сервиса након што се апликација и њени сервиси пребаце на Azure. Апликација за обраду поруџбине, која је описана у овом мастер раду,  има један део тестова генерисаних помоћу Silvera-е, док је један део писан ручно. Ручно писани су такозвани smoke тестови. Не постоји разлика између генерисаних тестова за Azure и  AWS,  ради се на исти начин. 

Сам приступ за генерисање тестова, другачији функционише од већ описаних процеса за фајлове међу којима су services.si, events.si, communication.si, entities.si. У оквиру ових фајлова постоји додатак који генератор test_generator.py користи и уз помоћ Jinja шаблона штампа се као стварни Python код, помоћу кога се ствара прави Python фајл. Тестови који су изгенерисани и који су смештени у tests/generated/ су api_surface.py, ту имамо чисте податке, међу којима је листа свих рута и топологија догађаја. Изгенерисан тест test_auth_enforcement.py тестира јавне руте, тестира руте без токена и са неважећим токеном, има и тест примери који покривају када се приступа са исправним токеном. Тест test_jwt_hardening.py испитује токене по сервису, тест test_messaging.py је задужен за испитивање порука. Што се самих догађаја тиче, покривени су тестовима тако што се проверава да ли постоји RabbitMQ exchange за сваки догађај који неко користи, проверавају се да ли за сваки модел за који треба да постоје редови везани за exchange заправо постоје. Битно је да се види да ли сваки ред има бар једног активног consumer-а и да ли је durable (ако модел то тражи), да ли dead-letter ред постоји тамо где је декларисан и бави се пријављивањем "orphan" догађаје на информативном нивоу. Ручно писани тестови су smoke тестови и то је урађено из разлога што су то тестови којима се тестира имплементаиција, а не сам ЈСД модел.

Тестови се покрећу из локала и постоје одређени кораци који требају бити испуњени како би се покренули. Ако се приступа из терминала потребно је прво да се осигура аутентификација са Azure  налогом коришћењем команди:

& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" login --tenant tenantId
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" account set --subscription subscriptionId 
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" aks get-credentials --resource-group order-tracking-rg --name order-tracking-aks

Треба покренути сервисе, препорука је да се покрену у оквиру пет одвојена терминала следеће команде:

kubectl port-forward svc/order-service 8081:80 -n order-tracking
kubectl port-forward svc/payment-service 8082:80 -n order-tracking
kubectl port-forward svc/tracking-service 8083:80 -n order-tracking
kubectl port-forward svc/notification-service  8084:80 -n order-tracking
kubectl port-forward svc/rabbitmq 15672:15672 -n order-tracking

Како би утврдили да гађамо праве сервисе, потребно је прво проверити да не гађају тестови сервисе у локалу командом  docker ps која треба да врати празно. Следећи корак ове провере је да се узму идентификатори процеса који се одвијају у  Kubernetes-у следећом командом 

Get-NetTCPConnection -LocalPort 8081,8082,8083,8084 -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess

На слици 6.10.4:1 колона OwningProcess заправо представља бројеве који су идентификатори процеса

 
#figure(image("../slike/slika-6.10.4-1.png", width: 90%), caption: [Приказ идентификатора процеса]) <slika-6-10-4-1>

На слици 6.10.4:12 имамо приказ тих процеса

 
#figure(image("../slike/slika-6.10.4-2.png", width: 90%), caption: [Приказ покренутих процеса у терминалу]) <slika-6-10-4-2>

Када имамо све проверено на овај начин, осигурано је да покренути тестови се извршавају на Azure платформи. Покретање тестова се врши тако што се прво навигира до директоријума где се налазе тестови, а затим покрену следећим комаднама

python tests\generated\test_auth_enforcement.py
python tests\generated\test_jwt_hardening.py
python tests\generated\test_messaging.py
python tests\smoke_test.py


Резултати покретања test_auth_enforcement.py тестова:

Section 1 — Public endpoints  (no token required)
─────────────────────────────────────
  [PASS] OrderService           GET    /health   (orders-db, rabbitmq)
  [PASS] OrderService           GET    /health/ready   (orders-db, rabbitmq)
  [PASS] PaymentService         GET    /health   (payments-db, rabbitmq)
  [PASS] PaymentService         GET    /health/ready   (payments-db, rabbitmq)
  [PASS] TrackingService        GET    /health   (rabbitmq, tracking-db)
  [PASS] TrackingService        GET    /health/ready   (rabbitmq, tracking-db)
  [PASS] NotificationService    GET    /health   (notifications-db, rabbitmq)
  [PASS] NotificationService    GET    /health/ready   (notifications-db, rabbitmq)
───────────────────────────────────────
  Section 2 — Missing token  (every [auth-required] route → 401)
───────────────────────────────────────
  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/4d24f7d7-637c-4f49-9fcb-5c6a9c020752
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/e39e0dad-95e8-4c42-8b6d-e9201928c38a/status
  [PASS] OrderService           DELETE /api/v1/orders/b16f5af4-2ad0-4c83-beca-dacd2f05a1ad
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/c7118ffb-9196-475a-a9dd-cf889f8158a7
  [PASS] PaymentService         GET    /api/v1/payments/order/ba6a541c-c164-4107-aed2-c24322a11041
  [PASS] PaymentService         PUT    /api/v1/payments/ca9f3bda-3105-4ab9-a815-2cbe564b6881/status
  [PASS] PaymentService         POST   /api/v1/payments/938bfcd9-f53a-419d-9861-cef49b375241/refund
  [PASS] TrackingService        GET    /api/v1/tracking/b7902f76-8c10-4b64-b458-b5d3cb77ef7d
  [PASS] TrackingService        GET    /api/v1/tracking/84bfff3e-24c1-439a-8e10-fca5059ea77a/history
  [PASS] TrackingService        GET    /api/v1/tracking/bbf03030-3c8f-4c3f-b691-0724c26df622/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/775ce0d0-018c-4781-ac5e-69b87d2b8649
  [PASS] NotificationService    POST   /api/v1/notifications/resend/783d7e29-b29f-4804-9112-8f07db5b6bea
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

─────────────────────────────────
  Section 3 — Invalid token  (wrong signing key → 401)
─────────────────────────────────
  A service that only checks for the presence of an Authorization
  header passes Section 2 and fails here.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/3fb7c8e1-0c12-421e-b093-b43ef49bd381
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/a713d3ad-3135-49b2-bac4-3216228cd104/status
  [PASS] OrderService           DELETE /api/v1/orders/2ff2a456-8553-4c39-9a71-6af358e98984
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/4d164c1e-9ab1-41f0-bfbb-9c5c6c355100
  [PASS] PaymentService         GET    /api/v1/payments/order/b89e8ab3-3d70-4f15-a54c-8e7228e3d89d
  [PASS] PaymentService         PUT    /api/v1/payments/61c2ef8f-a45e-467f-ae5a-0330b44344bc/status
  [PASS] PaymentService         POST   /api/v1/payments/545e734f-f972-4a39-84b9-5d0eba903dbf/refund
  [PASS] TrackingService        GET    /api/v1/tracking/d3045927-133c-44ed-b6f6-7df3005be784
  [PASS] TrackingService        GET    /api/v1/tracking/71baefec-fdf7-429c-853a-be29ee6916ff/history
  [PASS] TrackingService        GET    /api/v1/tracking/cfb37419-1cc9-4b1f-a5a1-db08a1bf0945/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/74d1128e-26d7-4af7-b6bc-4d8b9a91041a
  [PASS] NotificationService    POST   /api/v1/notifications/resend/50cadc60-581e-4cbc-8e29-625d10befc0c
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────
  Section 4 — Control  (a valid token must NOT be rejected)
───────────────────────────────────
  One read per service. A 401 here means Sections 2 and 3 passed
  because everything is rejected, not because auth works.

  [PASS] OrderService           GET    /api/v1/orders/ebbf111f-1233-494c-9164-4211087380b4
  [PASS] PaymentService         GET    /api/v1/payments/b3b62577-9a17-4a4b-8431-729d19dc69c0
  [PASS] TrackingService        GET    /api/v1/tracking/d926fcae-206d-4b9d-a4ad-bd525eece07e
  [PASS] NotificationService    GET    /api/v1/notifications
---
                   Results:  48 passed  0 failed  0 skipped  (48 total)
---
Резултати покретања test_jwt_hardening.py:

  JWT Hardening — generated from silvera/services.si
  8 bad-token case(s) against 4 service(s)
---
──────────────────────────
  Sections 1–4 — Bad tokens must be refused
──────────────────────────
  OrderService   GET /api/v1/orders/f7d7b613-cfed-42a9-8d0b-8cda7d613411
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  PaymentService   GET /api/v1/payments/84c68b3e-04f3-464d-91d2-00f21ff26d59
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  TrackingService   GET /api/v1/tracking/c1d7396e-f737-4076-8ae2-df76ff53ec55
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  NotificationService   GET /api/v1/notifications
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

──────────────────────────────────
  Control — a correctly signed token must NOT be refused
──────────────────────────────────
  Without this, a service that is down or that rejects everything
  would look perfectly hardened.

  [PASS] OrderService           GET /api/v1/orders/71b95420-ed1e-4212-9a8c-7a62ad0b9784
  [PASS] PaymentService         GET /api/v1/payments/e7f27d8c-a59b-48df-a95a-784a06e85655
  [PASS] TrackingService        GET /api/v1/tracking/d9f32da2-e6a0-4d83-9354-d1df7cdad189
  [PASS] NotificationService    GET /api/v1/notifications
---
  Results:  36 passed  0 failed  0 skipped  (36 total)
---
Резултати покретања test_messaging.py тестова:

   Messaging topology — generated from silvera/communication.si
  5 consumed event(s), 8 receive endpoint(s), 1 orphan(s)
---
  Section 1 — Broker reachable
───────────────────────────
  [PASS] RabbitMQ management API /api/overview
         broker version 3.13.7

────────────────────────────────
  Section 2 — Exchanges  (one per consumed event)
────────────────────────────────
  [PASS] OrderCancelledEvent        exchange declared
  [PASS] OrderCreatedEvent          exchange declared
  [PASS] OrderStatusChangedEvent    exchange declared
  [PASS] PaymentFailedEvent         exchange declared
  [PASS] PaymentProcessedEvent      exchange declared

───────────────────────────────────────────
  Section 3 — Fan-out  (exactly the queues the model routes each event to)
───────────────────────────────────────────
  A missing entry means that subscriber never started. A shared one
  means subscribers compete and each event reaches only one of them.

  [PASS] OrderCancelledEvent        → NotificationService, PaymentService, TrackingService
  [PASS] OrderCreatedEvent          → NotificationService, PaymentService, TrackingService
  [PASS] OrderStatusChangedEvent    → NotificationService, TrackingService
  [PASS] PaymentFailedEvent         → NotificationService, OrderService, TrackingService
  [PASS] PaymentProcessedEvent      → NotificationService, OrderService, TrackingService

───────────────────────────────────────────
  Section 4 — Receive endpoints  (the queues the subscription blocks name)
───────────────────────────────────────────
  [PASS] payment-service.order-created          OrderCreatedEvent
  [PASS] payment-service.order-cancelled        OrderCancelledEvent
  [PASS] order-service.payment-processed        PaymentProcessedEvent
  [PASS] order-service.payment-failed           PaymentFailedEvent
  [PASS] tracking-service.order-events          OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] tracking-service.payment-events        PaymentProcessedEvent, PaymentFailedEvent
  [PASS] notification-service.order-events      OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] notification-service.payment-events    PaymentProcessedEvent, PaymentFailedEvent

─────────────────────────────────────────
  Section 5 — Dead-letter queues  (targets named by dead-letter { })
─────────────────────────────────────────
  [PASS] dlq.payment-service.order-created          ← payment-service.order-created
  [PASS] dlq.payment-service.order-cancelled        ← payment-service.order-cancelled
  [PASS] dlq.order-service.payment-processed        ← order-service.payment-processed
  [PASS] dlq.order-service.payment-failed           ← order-service.payment-failed
  [PASS] dlq.tracking-service.order-events          ← tracking-service.order-events
  [PASS] dlq.tracking-service.payment-events        ← tracking-service.payment-events
  [PASS] dlq.notification-service.order-events      ← notification-service.order-events
  [PASS] dlq.notification-service.payment-events    ← notification-service.payment-events

─────────────────────────────────────────
  Section 6 — Orphan events  (informational)
─────────────────────────────────────────
  Published by a service, consumed by none. Nothing binds them, so
  the exchange may not exist at all. Not a broker fault — either a
  subscriber is missing from the model, or the event is dead weight.

  [SKIP] PaymentRefundedEvent       published by PaymentService, no subscribers
---
  Results:  27 passed  0 failed  1 skipped  (28 total)
---
Резултати smoke тестова су представљени на овај начин: 


  Order Tracking System — Integration Test Suite
  Mode: local   Section: all
---
  Section 1 — Health checks  (AddNpgSql registered → 'Healthy' = DB reachable)
──────────────────────────────────────────────────
  [PASS] OrderService           /health
  [PASS] OrderService           /health/ready
  [PASS] PaymentService         /health
  [PASS] PaymentService         /health/ready
  [PASS] TrackingService        /health
  [PASS] TrackingService        /health/ready
  [PASS] NotificationService    /health
  [PASS] NotificationService    /health/ready

───────────────────────────────────────────────────
  Section 2 — Auth enforcement  (every method, expect HTTP 401 without JWT)
───────────────────────────────────────────────────
  Driven by tests/generated/api_surface.py — every [auth-required]
  endpoint in silvera/services.si, including the mutating ones
  (POST/PUT/DELETE) where a missing [Authorize] matters most.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/d8e1600a-ace4-4a2c-bdde-85d924b3563a
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/829d829f-0976-4933-9fe9-c4f9fc912553/status
  [PASS] OrderService           DELETE /api/v1/orders/913ad841-8580-410e-9b8a-b948100fde5a
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/f3648747-2c26-44cb-9210-7da752d3bf5f
  [PASS] PaymentService         GET    /api/v1/payments/order/e5421a90-eaad-4de5-b1e2-b881b61798bf
  [PASS] PaymentService         PUT    /api/v1/payments/d7eb6230-b006-4f65-b840-d0f2d8a8664a/status
  [PASS] PaymentService         POST   /api/v1/payments/65dc30a9-5e04-4c9c-a990-151e8051c312/refund
  [PASS] TrackingService        GET    /api/v1/tracking/46d5eb76-cf66-4de6-b750-fedad4c7746b
  [PASS] TrackingService        GET    /api/v1/tracking/fa1c4b4c-f8bd-4b96-979f-71d2e5c49e3d/history
  [PASS] TrackingService        GET    /api/v1/tracking/5deca6ef-c34e-4343-8875-5396f5b2d920/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/637bb50c-78de-411f-911c-bcdeaca7e9d3
  [PASS] NotificationService    POST   /api/v1/notifications/resend/453544ce-f02d-4a7d-8038-70bb8a6eabb1
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────────────
  Section 3 — Authenticated reads + JSON schema validation
────────────────────────────────────────────

  3a. List endpoints — expect 200 with empty PagedResult
  [PASS] OrderService           GET /api/v1/orders?customerId=71ba3512-92be-405c-
  [PASS] PaymentService         GET /api/v1/payments/order/71ba3512-92be-405c-ba8
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd34
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd34
  [PASS] NotificationService    GET /api/v1/notifications
  [PASS] NotificationService    GET /api/v1/templates

  3b. Get-by-ID — expect 404 for unknown UUID
  [PASS] OrderService           GET /api/v1/orders/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] PaymentService         GET /api/v1/payments/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] NotificationService    GET /api/v1/notifications/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd3470e581e2/status

  3c. Pagination field values on OrderService list
  [PASS]   OrderService         page == 1
  [PASS]   OrderService         pageSize == 5
  [PASS]   OrderService         totalCount == 0
  [PASS]   OrderService         items == []

────────────────────────────────────────────
  Section 4 — Messaging infrastructure  (RabbitMQ management API)
────────────────────────────────────────────
  [PASS] RabbitMQ management API /api/overview
  [PASS] Response contains rabbitmq_version field
  [PASS] RabbitMQ exchanges present (22 found, 21 named)
  [PASS] An exchange exists for all 5 event types
  [PASS] RabbitMQ queues visible (16 queues — services connected if > 0)
  [PASS] Every queue is one the model names (16 expected)
  [PASS] All 8 receive endpoints exist
  [PASS] No orphaned queues (every consumer queue has a live consumer)
  [PASS] No messages in the model's dead-letter queues
  [PASS] No messages in MassTransit _error queues (no faulting consumers)
  [PASS] No messages in _skipped queues (no unroutable/dead messages)
  [PASS] All 4 services have active AMQP connections (4 connections found)

───────────────────────────────────────────
  Section 5 — Stub behaviour  (POST endpoints still unimplemented)
───────────────────────────────────────────
  OrderService's mapping stubs are implemented, so POST /api/v1/orders
  is covered by Section 6 instead. PaymentService still throws
  NotImplementedException from MapToRequest(); 400 = model binding
  rejected the empty body first. Both mean routing + auth worked.

  [PASS] PaymentService         POST /api/v1/payments

───────────────────────────────────────────
  Section 6 — End-to-end event flow  (publish → consume → persisted)
───────────────────────────────────────────
  [PASS] OrderService  POST /api/v1/orders → 201
  [PASS] Order total computed from line items (got 124.0, expected 124.00)

  waiting 8s for the event to propagate…
  [PASS] TrackingService  consumed OrderCreatedEvent (TrackingRecord written)
  [PASS] TrackingService  OrderTimeline snapshot updated
  [PASS] NotificationService  consumed the SAME event (fan-out, not competing)
  [PASS] OrderService  PUT /status → 200 (publishes OrderStatusChangedEvent)
  [PASS] TrackingService  timeline advanced to 2 events (expected >= 2)

──────────────────────────────────────
  Section 7 — Full API surface  (GET / POST / PUT / DELETE)
──────────────────────────────────────
  [PASS] Seed  POST /api/v1/orders → 201

  waiting 8s for consumers to populate tracking…

  [PASS] OrderService           GET    /api/v1/orders                             list by customer
  [PASS] OrderService           GET    /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3 get seeded order
  [PASS] OrderService           GET    /api/v1/orders/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] OrderService           PUT    /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3/status status transition
  [PASS] OrderService           DELETE /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3 cancel order
  [PASS] PaymentService         GET    /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] PaymentService         GET    /api/v1/payments/order/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 empty list, no mapping
  [PASS] PaymentService         POST   /api/v1/payments                           MapToRequest stub
  [PASS] PaymentService         PUT    /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/status stub / KeyNotFound
  [PASS] PaymentService         POST   /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/refund MapToRequest stub
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3 timeline records
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3/history history
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3/status timeline snapshot
  [PASS] TrackingService        GET    /api/v1/tracking/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/status untracked order → 404
  [PASS] NotificationService    GET    /api/v1/notifications                      list
  [PASS] NotificationService    GET    /api/v1/notifications/9fb7d9b0-768a-4979-8da4-e6d6d9450a77 get by id
  [PASS] NotificationService    GET    /api/v1/notifications/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] NotificationService    GET    /api/v1/templates                          list templates
  [PASS] NotificationService    POST   /api/v1/templates                          create
  [PASS] NotificationService    POST   /api/v1/notifications/resend/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 resend

  [PASS] NotificationService    verbs exercised: GET, POST
  [PASS] OrderService           verbs exercised: DELETE, GET, PUT
  [PASS] PaymentService         verbs exercised: GET, POST, PUT
  [PASS] TrackingService        verbs exercised: GET
  [PASS] All four HTTP verbs exercised across the system

───────────────────────────────────
  Section 8 — Data integrity  (round-trip + business rules)
────────────────────────────────────

  8a. POST then GET — every field must survive the round-trip
  [PASS] round-trip customerId
  [PASS] round-trip currency
  [PASS] round-trip notes
  [PASS] round-trip item count
  [PASS] round-trip shippingAddress (owned entity persisted)
  [PASS] round-trip line items (name / quantity / unitPrice)
  [PASS] totalAmount derived from items (124.00)
  [PASS] new order starts in PENDING

  8b. DELETE an order, then confirm tracking learned about it
  [PASS] DELETE /api/v1/orders/{id} → 204
  [PASS] cancelled order persists with status CANCELLED
  [PASS] TrackingService reflects the cancellation (cross-service consistency)

  8c. Pagination — page 1 and page 2 must differ
  [PASS] totalCount reports 3 seeded orders
  [PASS] page 1 returns pageSize=2 items
  [PASS] page 2 returns the remaining 1 item
  [PASS] pages do not overlap (real slicing, not the same rows twice)
  [PASS] totalPages computed correctly

───────────────────────────────────────────
  Section 9 — JWT hardening  (bad tokens must be rejected)
──────────────────────────────────────────
  [PASS] rejected: expired token (exp in the past)
  [PASS] rejected: wrong issuer
  [PASS] rejected: wrong audience
  [PASS] rejected: signed with the wrong key
  [PASS] rejected: valid claims, tampered signature
  [PASS] rejected: malformed token
  [PASS] rejected: empty bearer value
  [PASS] control: a correctly signed token is still accepted
---
  Results:  110 passed  0 failed  0 skipped  (110 total)
  All checks passed.

 

== Проширење Silvera-е подршком за деплојмент и тестирање на AWS платформи

Amazon Web Services (AWS) једно јако популарно окружење у облаку које се користи за развој и извршавање микросервисних апликација. Развила га је компанија Amazon . AWS пружа велики број сервиса које покривају готово све области развоја и одржавања апликација, укључујући рачунарске ресурсе, као што су виртуелне машине, контејнере и serverless функције, затим складиштење података, базе података, мрежне сервисе, безбедност и управљање приступом, вештачку интелигенцију и аналитику. Једна од највећих предности AWS-а је скалабилност, односно могућност повећања или смањења ресурса у складу са тренутним потребама апликације. Поред тога, AWS користи модел плаћања по потрошњи (pay-as-you-go), што значи да корисници плаћају само оне ресурсе које су заиста користили. 


=== Проширење метамодела и синтаксе

Идентична прича која је постојала као и за Azure, потребно је да се прошири Silvera-е и то је учињено на начин да се да додатна подршка код прављења самих модела. Та подршка је заправо коришћење метакласе Plugin. Као и раније што је поменуто, да би се користио Plugin додатак потребно је за почетак да се дефинише идентитет. Дефинисање идентитета је заправо одређивање назива, верзије и описа. Након тога потребно је написати циљну платформу (target) која је у овом случају AWS. Затим је потребно да се одредити и врста (kind), да ли је у питању deployment или testing. Врста се у овом случају назива још и дискриминатором, јер од ње зависи који ће се ток даље преузети. У конкретном апликацији када се изабере да је kind = deployment, тада се одабере ток који креира метакласе које омогућавају  пребацивање апликације на AWS. 

Семантички модел који омогућава пребацивање апликације на AWS је DeploymentTarget.

#figure(
  raw("name = 'AwsEc2Deployment'\\ntarget = 'aws-ec2'\\nregion = 'us-east-1'\\napp_name = 'order-tracking'\\ninstance_type = 't3.micro'\\ndisk_gb = 30\\nswap_gb = 6\\nallowed_ssh_cidr = '0.0.0.0/0'\\nallowed_app_cidr = '0.0.0.0/0'\\nmessaging_type = 'rabbitmq-container'\\nmessaging_mgmt_port = 15672", lang: "text"),
  caption: [Дефинисање AWS deployment модела],
) <listing-6-11-1-1>


=== Генерисање AWS конфигурације и пребацивање сервиса на AWS

Silvera модел који је задужен за генерисање AWS конфигурација је aws-ec2-deployment.si.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу aws-ec2-deployment.si  су дефинисане ствари које су потребне да буду подржане за креирање Terraform скрипти. Има следеће информације version, description, target, provider, compute, messaging. 

Како би пребацивање на AWS било могуће потребно је да постоји претходно креиран налог који има одређене претплате које би омогућиле покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату AWS Free Tier   и имала сам могућност да добијем првих 100 долара бесплатног кредита који могу да користим наредна три месеца, уз одређена ограничења. AWS сервиси су поприлично скупи, па је било потребно да се обрати пажња да се изаберу неке јефтинија верзија, како се не би одмах потрошио читав кредит. Након што је све изгенерисано, потребно је да се покрену ове команде, да се дода кључ и тајна са AWS налога, на тај начин је омогућен приступ, након тога aws configure и након тога terraform apply.

 
#figure(image("../slike/slika-6.11.2-1.png", width: 90%), caption: [Приказ EC2 инстанци]) <slika-6-11-2-1>

 
#figure(image("../slike/slika-6.11.2-2.png", width: 90%), caption: [Детаљан order-tracking-sg приказ ресурса]) <slika-6-11-2-2>

 
=== Тестирање имплементираног решења на AWS платформи

 	Као што је већ споменуто генерисање тестова за Azure и AWS се одвија на исти начин, јер је су фајлови services.si, events.si, communication.si, entities.si где се налазе Silvera модели проширени како би подржали генерисање тестова. Овде су такође smoke тестови ручно направљени из истих разлога, јер се њима тестира сама имплементација, а не сами ЈСД модели. Детаљније о самим тестовима и њиховом дефинисању у оквиру апликације налази се у поглављу  6.10.4 Тестирање имплементираног решења на Azure платоформи. Пошто су исти тестови, како би тестирали њихово понашање на различитим платформама, битан је начин на који се све ово покреће. Међу првим корацима је то да се преко терминала улогује на одговарајући AWS налог, где су постављени сервиси. Потребно је покренути команде, чији излаз бу требао да буде running 3.84.174.154

aws ec2 describe-instances --instance-ids i-076084e187740f8e0 --region us-east-1 ` --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" --output text


Проверити да ли се овде враћа као статус health, за следеће команде

curl http://3.84.174.154:8081/health
curl http://3.84.174.154:8082/health
curl http://3.84.174.154:8083/health
curl http://3.84.174.154:8084/health

Команде за покретање тестова су:

 	python test_auth_enforcement.py `
--order-service-url http://3.84.174.154:8081 `
--payment-service-url http://3.84.174.154:8082 `
--tracking-service-url http://3.84.174.154:8083 `
--notification-service-url http://3.84.174.154:8084

python test_messaging.py --broker-url http://3.84.174.154:15672 --broker-user guest --broker-password guest

python test_jwt_hardening.py `
--order-service-url http://3.84.174.154:8081 `
   --payment-service-url http://3.84.174.154:8082 `
--tracking-service-url http://3.84.174.154:8083 `
--notification-service-url http://3.84.174.154:8084
&  "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" tests/smoke_test.py 
       -- mode aws `
       --order-url http://3.84.174.154:8081 `
       --payment-url http://3.84.174.154:8082 `
       --tracking-url http://3.84.174.154:8083 `
        --notification-url http://3.84.174.154:8084 `
 --rabbitmq-url http://3.84.174.154:15672

Резултати када се покрену тестови из test_auth_enforcement.py


  Auth Enforcement — generated from silvera/services.si
  18 protected / 8 public endpoints across 4 services
---
  OrderService           http://3.84.174.154:8081
  PaymentService         http://3.84.174.154:8082
  TrackingService        http://3.84.174.154:8083
  NotificationService    http://3.84.174.154:8084

─────────────────────────────────
  Section 1 — Public endpoints  (no token required)
─────────────────────────────────
  [PASS] OrderService           GET    /health   (orders-db, rabbitmq)
  [PASS] OrderService           GET    /health/ready   (orders-db, rabbitmq)
  [PASS] PaymentService         GET    /health   (payments-db, rabbitmq)
  [PASS] PaymentService         GET    /health/ready   (payments-db, rabbitmq)
  [PASS] TrackingService        GET    /health   (rabbitmq, tracking-db)
  [PASS] TrackingService        GET    /health/ready   (rabbitmq, tracking-db)
  [PASS] NotificationService    GET    /health   (notifications-db, rabbitmq)
  [PASS] NotificationService    GET    /health/ready   (notifications-db, rabbitmq)

──────────────────────────────────────
  Section 2 — Missing token  (every [auth-required] route → 401)
──────────────────────────────────────
  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/3910dabe-a534-4079-9264-21c0d2783de7
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/655ac7df-54e4-4504-a4a2-ecdfd79484cb/status
  [PASS] OrderService           DELETE /api/v1/orders/94d7cff4-90d0-4f0d-a328-51773a3eaa35
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/bb5c9e37-b6a5-48ea-952d-6fbcec71f6f8
  [PASS] PaymentService         GET    /api/v1/payments/order/d1476676-5f7c-4ab8-8d76-e585348a0436
  [PASS] PaymentService         PUT    /api/v1/payments/8c202a4f-09b5-4c15-aa0c-474310b6d23d/status
  [PASS] PaymentService         POST   /api/v1/payments/f7436a9a-7ed4-4d48-b1f6-146cf5b200e2/refund
  [PASS] TrackingService        GET    /api/v1/tracking/cdc29b4c-3097-4e93-b7bc-ab63aac99343
  [PASS] TrackingService        GET    /api/v1/tracking/15f9349a-602c-4cf0-982a-4543b8a221dd/history
  [PASS] TrackingService        GET    /api/v1/tracking/0879205d-5f6f-4b77-9e61-7cc55c977f58/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/96dde481-2ee9-4940-a860-6d59a1e3e963
  [PASS] NotificationService    POST   /api/v1/notifications/resend/c1c3a80b-470e-44ef-ac08-d7fea221edd1
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

─────────────────────────────────
  Section 3 — Invalid token  (wrong signing key → 401)
─────────────────────────────────
  A service that only checks for the presence of an Authorization
  header passes Section 2 and fails here.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/f18a82e5-fe1e-482d-8a40-101d54c89828
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/e9fabc13-d0be-45d4-9f06-4a261e5808cc/status
  [PASS] OrderService           DELETE /api/v1/orders/62c6f0a3-5a31-471d-884f-6a1cb71651b2
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/f5b4a6ec-688e-4764-b968-9de9dc87e738
  [PASS] PaymentService         GET    /api/v1/payments/order/7cb719e9-c927-4273-ac53-0eb2e3a88c0c
  [PASS] PaymentService         PUT    /api/v1/payments/fe99d4a0-7707-4f1b-b1c0-45c3feaed156/status
  [PASS] PaymentService         POST   /api/v1/payments/33eedee8-3136-463b-8a81-048422af1302/refund
  [PASS] TrackingService        GET    /api/v1/tracking/c54ccffb-22d2-4991-8a73-6b39ad25f119
  [PASS] TrackingService        GET    /api/v1/tracking/de0cbbbd-6f1c-4638-81f1-4e0f72637f6c/history
  [PASS] TrackingService        GET    /api/v1/tracking/9c3e0e15-b1eb-45d3-a0d8-d75ccc1509f3/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/d29e20cc-dbb0-473e-b970-1c853ad03f90
  [PASS] NotificationService    POST   /api/v1/notifications/resend/c94c9071-914d-458f-b865-a76f8cb4c8f5
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

───────────────────────────────────
  Section 4 — Control  (a valid token must NOT be rejected)
───────────────────────────────────
  One read per service. A 401 here means Sections 2 and 3 passed
  because everything is rejected, not because auth works.

  [PASS] OrderService           GET    /api/v1/orders/6bfd7602-48f2-4886-b6ab-f672086e9454
  [PASS] PaymentService         GET    /api/v1/payments/3a5cae11-0e5e-4d33-8896-15fd014e2f66
  [PASS] TrackingService        GET    /api/v1/tracking/982648f0-04d2-4333-95bf-6f4c44e71146
  [PASS] NotificationService    GET    /api/v1/notifications
---
  Results:  48 passed  0 failed  0 skipped  (48 total)
---
Резултати када се покрену тестови из test_messaging.py
                                         
  Messaging topology — generated from silvera/communication.si                                                
  5 consumed event(s), 8 receive endpoint(s), 1 orphan(s)
  Broker: http://3.84.174.154:15672
---
  Section 1 — Broker reachable
───────────────────
  [PASS] RabbitMQ management API /api/overview
         broker version 3.13.7

────────────────────────────────
  Section 2 — Exchanges  (one per consumed event)
───────────────────────────────
  [PASS] OrderCancelledEvent        exchange declared
  [PASS] OrderCreatedEvent          exchange declared
  [PASS] OrderStatusChangedEvent    exchange declared
  [PASS] PaymentFailedEvent         exchange declared
  [PASS] PaymentProcessedEvent      exchange declared

────────────────────────────────────────────
  Section 3 — Fan-out  (exactly the queues the model routes each event to)
────────────────────────────────────────────
  A missing entry means that subscriber never started. A shared one
  means subscribers compete and each event reaches only one of them.

  [PASS] OrderCancelledEvent        → NotificationService, PaymentService, TrackingService
  [PASS] OrderCreatedEvent          → NotificationService, PaymentService, TrackingService
  [PASS] OrderStatusChangedEvent    → NotificationService, TrackingService
  [PASS] PaymentFailedEvent         → NotificationService, OrderService, TrackingService
  [PASS] PaymentProcessedEvent      → NotificationService, OrderService, TrackingService

────────────────────────────────────────────
  Section 4 — Receive endpoints  (the queues the subscription blocks name)
────────────────────────────────────────────
  [PASS] payment-service.order-created          OrderCreatedEvent
  [PASS] payment-service.order-cancelled        OrderCancelledEvent
  [PASS] order-service.payment-processed        PaymentProcessedEvent
  [PASS] order-service.payment-failed           PaymentFailedEvent
  [PASS] tracking-service.order-events          OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] tracking-service.payment-events        PaymentProcessedEvent, PaymentFailedEvent
  [PASS] notification-service.order-events      OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] notification-service.payment-events    PaymentProcessedEvent, PaymentFailedEvent

────────────────────────────────────────
  Section 5 — Dead-letter queues  (targets named by dead-letter { })
────────────────────────────────────────
  [PASS] dlq.payment-service.order-created          ← payment-service.order-created
  [PASS] dlq.payment-service.order-cancelled        ← payment-service.order-cancelled
  [PASS] dlq.order-service.payment-processed        ← order-service.payment-processed
  [PASS] dlq.order-service.payment-failed           ← order-service.payment-failed
  [PASS] dlq.tracking-service.order-events          ← tracking-service.order-events
  [PASS] dlq.tracking-service.payment-events        ← tracking-service.payment-events
  [PASS] dlq.notification-service.order-events      ← notification-service.order-events
  [PASS] dlq.notification-service.payment-events    ← notification-service.payment-events

─────────────────────────────
  Section 6 — Orphan events  (informational)
─────────────────────────────
  Published by a service, consumed by none. Nothing binds them, so
  the exchange may not exist at all. Not a broker fault — either a
  subscriber is missing from the model, or the event is dead weight.

  [SKIP] PaymentRefundedEvent       published by PaymentService, no subscribers
---
  Results:  27 passed  0 failed  1 skipped  (28 total)
---
Резултати када се покрену тестови из jwt_hardening.py

  JWT Hardening — generated from silvera/services.si
  8 bad-token case(s) against 4 service(s)
---
  Sections 1–4 — Bad tokens must be refused
──────────────────────────────

  OrderService   GET /api/v1/orders/36605b51-c820-4500-a494-05fe1307ec7b
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  PaymentService   GET /api/v1/payments/d8fe7711-e6f7-4f7e-92f6-75dbc672e29a
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  TrackingService   GET /api/v1/tracking/d1bad770-6681-46c9-96d7-9717a42df82d
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  NotificationService   GET /api/v1/notifications
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

───────────────────────────────────
  Control — a correctly signed token must NOT be refused
─────────────────────────────────────
  Without this, a service that is down or that rejects everything
  would look perfectly hardened.

  [PASS] OrderService           GET /api/v1/orders/48ff5f9d-70e7-4596-b2ae-52da8e2aab4c
  [PASS] PaymentService         GET /api/v1/payments/cff9967d-c0fc-4063-8ca0-3df4fa5d81be
  [PASS] TrackingService        GET /api/v1/tracking/45cc542a-1236-4b57-a87f-837394e899cf
  [PASS] NotificationService    GET /api/v1/notifications
---
  Results:  36 passed  0 failed  0 skipped  (36 total)
---
Резултати када се покрену smoke тестови
 
Order Tracking System — Integration Test Suite
  Mode: aws   Section: all
---
  Section 1 — Health checks  (AddNpgSql registered → 'Healthy' = DB reachable)
───────────────────────────────────────────────────
  [PASS] OrderService           /health
  [PASS] OrderService           /health/ready
  [PASS] PaymentService         /health
  [PASS] PaymentService         /health/ready
  [PASS] TrackingService        /health
  [PASS] TrackingService        /health/ready
  [PASS] NotificationService    /health
  [PASS] NotificationService    /health/ready

───────────────────────────────────────────────
  Section 2 — Auth enforcement  (every method, expect HTTP 401 without JWT)
───────────────────────────────────────────────
  Driven by tests/generated/api_surface.py — every [auth-required]
  endpoint in silvera/services.si, including the mutating ones
  (POST/PUT/DELETE) where a missing [Authorize] matters most.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/12a287a4-7a0a-4911-bb5d-5fdd36aebb8b
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/97d8583e-f5f9-4f46-8de2-4b7512658076/status
  [PASS] OrderService           DELETE /api/v1/orders/f92f48d4-9996-4dba-a240-a75ab902858f
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/8e6427a5-7cd2-46f0-ad00-0fa67dc14e15
  [PASS] PaymentService         GET    /api/v1/payments/order/2cb41413-b273-4dd4-8b65-5433a1a7cff2
  [PASS] PaymentService         PUT    /api/v1/payments/62e6d7a9-926f-4b3a-93ba-f192b913cff4/status
  [PASS] PaymentService         POST   /api/v1/payments/291108f2-bc4c-4d60-a2ec-6b0f53341c4d/refund
  [PASS] TrackingService        GET    /api/v1/tracking/15e4318a-0273-4a50-b8e6-4e16c77072be
  [PASS] TrackingService        GET    /api/v1/tracking/3a461daf-5119-41aa-8676-103d7d0e633b/history
  [PASS] TrackingService        GET    /api/v1/tracking/a8843e03-c508-4e1f-bfec-40dc55d576e9/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/d4fd8757-bad9-4de9-a02b-4dd02257d56c
  [PASS] NotificationService    POST   /api/v1/notifications/resend/1d23a677-b2ec-458c-a6f4-9bf96c8c9d28
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────
  Section 3 — Authenticated reads + JSON schema validation
────────────────────────────────────

  3a. List endpoints — expect 200 with empty PagedResult
  [PASS] OrderService           GET /api/v1/orders?customerId=951b31d8-0a3c-469d-
  [PASS] PaymentService         GET /api/v1/payments/order/951b31d8-0a3c-469d-b19
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209
  [PASS] NotificationService    GET /api/v1/notifications
  [PASS] NotificationService    GET /api/v1/templates

  3b. Get-by-ID — expect 404 for unknown UUID
  [PASS] OrderService           GET /api/v1/orders/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] PaymentService         GET /api/v1/payments/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] NotificationService    GET /api/v1/notifications/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209f2459d18/status

  3c. Pagination field values on OrderService list
  [PASS]   OrderService         page == 1
  [PASS]   OrderService         pageSize == 5
  [PASS]   OrderService         totalCount == 0
  [PASS]   OrderService         items == []

─────────────────────────────────────────
  Section 4 — Messaging infrastructure  (RabbitMQ management API)
─────────────────────────────────────────
  [PASS] RabbitMQ management API /api/overview
  [PASS] Response contains rabbitmq_version field
  [PASS] RabbitMQ exchanges present (22 found, 21 named)
  [PASS] An exchange exists for all 5 event types
  [PASS] RabbitMQ queues visible (16 queues — services connected if > 0)
  [PASS] Every queue is one the model names (16 expected)
  [PASS] All 8 receive endpoints exist
  [PASS] No orphaned queues (every consumer queue has a live consumer)
  [PASS] No messages in the model's dead-letter queues
  [PASS] No messages in MassTransit _error queues (no faulting consumers)
  [PASS] No messages in _skipped queues (no unroutable/dead messages)
  [PASS] All 4 services have active AMQP connections (4 connections found)

─────────────────────────────────────────
  Section 5 — Stub behaviour  (POST endpoints still unimplemented)
─────────────────────────────────────────
  OrderService's mapping stubs are implemented, so POST /api/v1/orders
  is covered by Section 6 instead. PaymentService still throws
  NotImplementedException from MapToRequest(); 400 = model binding
  rejected the empty body first. Both mean routing + auth worked.

  [PASS] PaymentService         POST /api/v1/payments

──────────────────────────────────────────
  Section 6 — End-to-end event flow  (publish → consume → persisted)
──────────────────────────────────────────
  [PASS] OrderService  POST /api/v1/orders → 201
  [PASS] Order total computed from line items (got 124.0, expected 124.00)

  waiting 8s for the event to propagate…
  [PASS] TrackingService  consumed OrderCreatedEvent (TrackingRecord written)
  [PASS] TrackingService  OrderTimeline snapshot updated
  [PASS] NotificationService  consumed the SAME event (fan-out, not competing)
  [PASS] OrderService  PUT /status → 200 (publishes OrderStatusChangedEvent)
  [PASS] TrackingService  timeline advanced to 2 events (expected >= 2)

─────────────────────────────────────
  Section 7 — Full API surface  (GET / POST / PUT / DELETE)
──────────────────────────────────────
  [PASS] Seed  POST /api/v1/orders → 201

  waiting 8s for consumers to populate tracking…

  [PASS] OrderService           GET    /api/v1/orders                             list by customer
  [PASS] OrderService           GET    /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76 get seeded order
  [PASS] OrderService           GET    /api/v1/orders/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] OrderService           PUT    /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76/status status transition
  [PASS] OrderService           DELETE /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76 cancel order
  [PASS] PaymentService         GET    /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] PaymentService         GET    /api/v1/payments/order/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 empty list, no mapping
  [PASS] PaymentService         POST   /api/v1/payments                           MapToRequest stub
  [PASS] PaymentService         PUT    /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/status stub / KeyNotFound
  [PASS] PaymentService         POST   /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/refund MapToRequest stub
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76 timeline records
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76/history history
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76/status timeline snapshot
  [PASS] TrackingService        GET    /api/v1/tracking/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/status untracked order → 404
  [PASS] NotificationService    GET    /api/v1/notifications                      list
  [PASS] NotificationService    GET    /api/v1/notifications/6bb5a157-35c0-43f5-8eae-ebed9afa5d13 get by id
  [PASS] NotificationService    GET    /api/v1/notifications/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] NotificationService    GET    /api/v1/templates                          list templates
  [PASS] NotificationService    POST   /api/v1/templates                          create
  [PASS] NotificationService    POST   /api/v1/notifications/resend/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 resend

  [PASS] NotificationService    verbs exercised: GET, POST
  [PASS] OrderService           verbs exercised: DELETE, GET, PUT
  [PASS] PaymentService         verbs exercised: GET, POST, PUT
  [PASS] TrackingService        verbs exercised: GET
  [PASS] All four HTTP verbs exercised across the system

───────────────────────────────────
  Section 8 — Data integrity  (round-trip + business rules)
───────────────────────────────────

  8a. POST then GET — every field must survive the round-trip
  [PASS] round-trip customerId
  [PASS] round-trip currency
  [PASS] round-trip notes
  [PASS] round-trip item count
  [PASS] round-trip shippingAddress (owned entity persisted)
  [PASS] round-trip line items (name / quantity / unitPrice)
  [PASS] totalAmount derived from items (124.00)
  [PASS] new order starts in PENDING

  8b. DELETE an order, then confirm tracking learned about it
  [PASS] DELETE /api/v1/orders/{id} → 204
  [PASS] cancelled order persists with status CANCELLED
  [PASS] TrackingService reflects the cancellation (cross-service consistency)

  8c. Pagination — page 1 and page 2 must differ
  [PASS] totalCount reports 3 seeded orders
  [PASS] page 1 returns pageSize=2 items
  [PASS] page 2 returns the remaining 1 item
  [PASS] pages do not overlap (real slicing, not the same rows twice)
  [PASS] totalPages computed correctly

─────────────────────────────────────
  Section 9 — JWT hardening  (bad tokens must be rejected)
─────────────────────────────────────
  [PASS] rejected: expired token (exp in the past)
  [PASS] rejected: wrong issuer
  [PASS] rejected: wrong audience
  [PASS] rejected: signed with the wrong key
  [PASS] rejected: valid claims, tampered signature
  [PASS] rejected: malformed token
  [PASS] rejected: empty bearer value
  [PASS] control: a correctly signed token is still accepted
---
  Results:  110 passed  0 failed  0 skipped  (110 total)
  All checks passed.
---
Тестови који се овде извршавају локално комуницирају са сервисима који су доступни на AWS EC2 инстанцама. Циљ је да покрију што већу функционалност и међусобну комуникацију сервиса у окружењу које је блиско реалном продукционом окружењу. Овим приступом се на једноставнији начин врши провера интеграције микросервисне апликације и представља једну од могућности за њено извршавање и тестирање у AWS облаку.
 
/*
6.7.1	Архитектура генерисаног решења

Како би апликација била генерисана неопходно је да се прво сви фајлови silvera/*.si парсирају, за то је могуће користити textX граматику. Граматика је смештена у фајлу silvera.tx. Након тога се од Silvera модела, праве Python класе silvera/model/types.py уз  помоћ генератора (Jinja2 шаблона) добијају се .NET пројекти, Dockerfile-ovi, K8s манифести, Terraform. 


 

#figure(image("../slike/slika-6.4.1-1.png", width: 90%), caption: [Ток генерисања апликације])

Архитектура апликације генерисана на три нивоа. Први ниво је архитектура самог модела а обухвата домени, ентитети, догађаји и сервиси организовани у Silvera-и, други ниво је архитектуру генератора у којој спада компајлерски pipeline који модел претвара у код и трећи ниво је архитектуру система који настаје на излазу микросервиси, база, message broker, инфраструктура. 

Архитектура самог модела има јасну хијерархијску зависност. Модел domains.si дефинише bounded context -е и не зависи ни од чега, модел entities.si увози домене и додаје ентитете/enum-ове. Модел events.si служе за увоз ентитета и дефинишу интеграционе догађаје, док  services.si  модел увози сва претходна три и повезује их у сервисе. На самом крају се налази communication.si, где се увозе сервиси и догађаји, додаје се топологију комуникације као што су REST позиви, event-канали, subscription-и. Наведени модели су основни део система, док модели који одређују где ће систем бити су silvera/plugins/azure-deployment.si и aws-deployment.si и он обезбеђују да претходно наведени модели могу бити подржани на Azure/ AWS без додатних измена у моделу и у потпуности су независни.

Архитектура генератора се састоји од дела где се парсира текста у стабло. Постоје две стратегије парсирања, прво се покушава са textX библиотеку над формалном граматиком silvera.tx, а ако textX није инсталиран или парсирање не успе, прелази се на ручно написан regex-парсер (loader.py) који разуме исти ЈСД директно из текста. Оба пута производе исти SilveraModel. Затим је то потребно да се преведе у Python модел који је независан од синтаксе. То се ради уз помоћ низа независних backend-ова (генератора), који их преводе у различите циљне артефакте. Конкретно за апликацију која се развија за овај мастер рад структура је подељена тако да се у фолдеру parser/  смештају производи SilveraModel (dataclass-ови у model/types.py), док generators/ садржи четири потпуно независна модула који тај исти објекат користе. Ниједан генератор не зна нити зависи од тога како је модел настао. 

Крајња архитектура апликације јесу четри независна микросервиса, заједничка библиотека (SharedKernel), event-driven комуникација преко message broker-a, где је RabbitMQ подразумевано, а Azure Service Bus / AWS SQS-SNS као plugin-ови који се могу заменити без измене кода, заједничка PostgreSQL база са одвојеном шемом по сервису (schema-per-service), JWT аутентикација, Serilog логовање и OpenTelemetry праћење. Све је ово претходно описано у оквиру модела, а касније је уз помоћ генератора и материјализовано. Из истог ЈСД модела може да се генерише и  апликативни и инфраструктурни ниво архитектуре.


6.7.2	Генерисање микросервиса

Процес превођење Silvera модела у микросервисе .NET језика се одвија када frontend Silvera преводилац заврши парсирање и семантичку анализу свих .si датотека. Тада се добија инстанца класе SilveraModel која је Python објекат. Садржи потпуно апстрактну репрезентацију система. Апстрактнa репрезентацијa система је листа ентитета, енумерација, догађаја и сервиса, као и односе међу њима. Овај модел се прослеђује backend делу преводиоца, конкретно модулу dotnet_generator.py, чија је једина одговорност да за сваки сервис из model.services произведе комплетан ASP.NET Core 8 пројекат. Улазна тачка целог процеса је скрипта generate.py, која прво учитава све .si датотеке функцијом load_model(), затим у зависности од изабраног циља (--target dotnet|docker|k8s|terraform) позива одговарајући генератор. За .NET циљ то је функција generate_services(model, output_dir), која итерира кроз сваки елемент листе model.services и за сваки позива приватну функцију _generate_service(). Поред сервиса, на крају се генерише и заједнички пројекат SharedKernel. Он садржи уговоре о догађајима и инфраструктурне екстензије дељене од стране свих сервиса. Свака .NET датотека настаје рендеровањем одговарајућег Jinja2 шаблона (.j2) над контекстом изведеним из модела. Генератор дефинише сопствено Jinja2 окружење са неколико прилагођених филтера који решавају разлику између ознака Silvera језика и C# конвенција именовања.

За сваки сервис, зове се приватна функција _generate_service(). Уколико постоји енумерација за неки ентитет то се прво прикупља, од тога гради заједнички контекст који се прослеђује свим шаблонима тог сервиса. На основу овог контекста, редом се генерише пројекта датотека а циљним оквиром . NET 8.0 и пакетима одређеним пољима technology из Silvera декларације и означене су као {Service}.csproj(csproj.j2). Модели C# класе за сваки ентитет и уграђени value object, означени су као Models.cs(models.j2). Када је за сервисе потребна конекција ка бази података, потребно је да се дефинише DbSet<T> за сваки ентитет и мапира их на PostgreSQL шему наведену у db-schema атрибуту. Фајлови тада носе назив по шаблону Data/{Service}DbContext.cs(dbcontext.j2). Уколико сервис има дефинисане endpoints, садржи уговор и имплементацију пословне логике над примарним ентитетом, укључујући детекцију статусне енумерације, тада се ради генерисања методе за промену стања, након чега се генеришу фајлови Services/I{Service}.cs. Ако постоји потреба да се дефинише endpoints где је потребно да се генерише HTTP акција, HTTP метод, рута и назив операције, то се преузима директно из endpoints блока Silvera декларације сервиса. Фајлови који тада настају називају се Controllers/{Entity}sController.cs(controller.j2). За сервис који садржи subscribes правила генерише се фајл Events/Handlers/EventHandlers.cs(event_handler.j2). Сваки .NET пројекат има Program.cs(program.j2), ту је смештена bootstrap класа која региструје аутентикацију, логовање, тракинг и messaging инфраструктуру на основу technology и health-checks блокова сервиса. Обавезан је и фајл appsettings.json (appsettings.j2) конфигурациона датотека са connection string-ом, RabbitMQ хостом и JWT подешавањима.

Генерисан код се означава на тај начин што свака генерисана датотека садржи коментар // <auto-generated>. Урађено је на тај начин да би се олакшао посао генератору, који се када се поново покрене са опцијом --clean безбедно уклони само претходно генерисане артефакте, не додирујући ручно дописану пословну логику ван означених TO DO блокова. Резултат овог поступка, поновљеног за сва четири сервиса (OrderService, PaymentService, TrackingService, NotificationService)  јесте потпуна .NET 8 структура, генерисана искључиво на основу декларација у silvera/*.si датотекама, без иједне ручно писане линије инфраструктурног кода. 


6.8	Генерисање Docker конфигурације

 	Генерисање Docker фајлова у Silverа-и функционише на тај начин да имамо четири Dockerfile-a и један compose фајл. Dockerfile-ови иду кроз Jinja2  шаблон, док је compose укуцан као Python string. На слици 6.3.3:1 је приказан како се по сервису од модела дође до Docker фајла 

 


#figure(image("../slike/slika-6.3.3-1.png", width: 90%), caption: [Дијаграм који показује пут од модела до Docker фајла по сервису])


	Docker фајл у Silverа-и се генеришу по сервисима. Основни шаблон је приказан на слици 6.3.3:2, мењају се само service.name и service.port у зависности за који сервис се генеришу. 

 
#figure(image("../slike/slika-6.3.3-2.png", width: 90%), caption: [Шаблон за прављење Docker фајлова по сервисима])



6.9	Генерисање Terraform и Kubernetes конфигурације

У оквиру Silvera-e главни део модела за Terraform је написан у aws-depoyment.si и azure-deployment.si фајловима. Унутар ових фајлова је дефинисано како да се направи све што је потребно за AWS/Azure налог, затим регистровање контејнера и Kubernetes кластера, дефинисање базе, начина слања порука, мониторинг и потребан фајл где се чувају скривене битне информације везане за базу и сервисе. Након што се изгенерише апликација добијемо два одвојена фолдера за AWS и Azure, који имају исту структуру. Структура се може видети на слици 6.9:1. 

 
#figure(image("../slike/slika-6.9-1.png", width: 90%), caption: [Структура фолдера за AWS и Azure])

	На слици 6.9:2 је описано како тече сам процес генерисања свих фајлова који су неопходни Terraform-у. 
 
#figure(image("../slike/slika-6.9-2.png", width: 90%), caption: [Структура фајлова за Terraform])
Што се тиче самог Kubernetes, доста је погодан алат за апликацију која треба да аутоматизује процес пребацивања апликације на облак, јер ако се све постави лепо у старту, нема потребе за додатним интервенцијама и ручним подешавањима. Кључна улога код генерисања Kubernetes игра функција generate_k8s_manifests, која се налази у оквиру kubernetes_generator.py. То је обична Python функција која је приказана на слици 6.3.4:2.

 
#figure(image("../slike/slika-6.3.4-2.png", width: 90%), caption: [Приказ функције generate_k8s_manifest])

 	
 	Функција generate_k8s_manifests се састоји из три фазе. Прва фаза је припрема, где се инстанцира Jinja2 Environment, друга фаза итерира кроз model.services и за сваки ServiceDef рендерује deployment.j2. Из модела користи само три вредности, а то су име, порт и изведени назив конекционог стринга, резултат ове фазе су 4 манифест фајлова. На крају се  прави заједнички манифести (yaml фајлови) namespace, configMap, secret и ingress. Ови не иду кроз шаблон него су hardcoded Python стрингови, резултат ове фазе су 8 фајлова. Једини фајл који је потребно ручно написати је rabbitmq.yaml. 

У случају саме апликације за обраду поруџбине генерисане уз помоћ Silvera-e прво Terraform направи празан кластер. Kubernetes манифест фајлови га онда попуни изгенерисаним сервисима. Важно је да се напомене Terraform  покреће једном, док се манифест фајлови покреће приликом сваког deploy. Укратко, Docker све спакује, Terraform прави место где ће радити, а  Kubernetes покреће. За микросервисној архитектури, где постоји велики број независних сервиса, Terraform и Kubernetes доста поједностављују управљање системом. Terraform омогућава поновљиво креирање истих окружења (development, testing, production), док је Kubernetes обезбеђено поуздано извршавање сервиса и динамичко прилагођавање оптерећењу. Управо из ових разлога Terraform и Kubernetes су циљне технологије које се користе за аутоматизацију самог процеса пребацивања апликације на cloude платформе која се генерише коришћењем Silvera-e. ЈСД може поједноставнити сложеност ових технологија тако што корисник описује архитектуру система на вишем нивоу, док се конкретне Terraform и Kubernetes конфигурације генеришу аутоматски.
 
6.10	Проширење Silvera-е подршком за пребацивање апликације и тестирање на Azure платформи

Azure платформа је једно од најраспрострањенијих окружења у облаку, који се користи за развој и извршавање микросервисних апликација. Нуди велики број сервиса који омогућавају скалабилност, високу доступност и једноставно управљање ресурсима. Да би интеграција Silvera-е са Azure платформом била могућа модел треба да се прошити да поред генерисања изворног кода, садржи и информације неопходне за аутоматско креирање конфигурација за пребацивање  и извршавање апликације у облаку. 


6.10.1	Мотивација за проширење
	
Потребе савременог софтверског инжењерства захтевају да апликација буде подржана у облаку, поготово ако је реч о микросервисној апликацији. Употребом Silvera-е могуће је да се моделује микросервисна архитектура и да се одради аутоматско генерисање изворног кода. Аутоматизовано постављање у облаку, тестирање и управљање животним циклусом апликације није подржано тим основним циклусом у Silvera-и, па се ту јавила потреба за проширењем. У пракси, процес пребацивања на облачно окружења често захтева да се ручно конфигурише инфраструктуре, дефинишу сервиси, мрежна подешавања и параметар окружења. 

Главна мотивација је да се смањује количина ручног рада и да се упрости процес постављања микросервисне апликације. Из тих разлога јавила се потреба да се што већи део животног циклуса развоја софтвера подржи у оквиру Silvera-е. Проширењем Silvera-е тако да се генеришу неопходни артефаката за пребацивање на Azure платформи, би у великој мери била смањена количина ручног рада и поједностављује процес пребацивања микросервисне апликације. Омогућава аутоматизовано тестирање успешно пребачених сервиса, чиме се обезбеђује да генерисана апликација не само да буде исправно креирана, већ и функционално проверена након постављања.

6.10.2	Проширење метамодела и синтаксе

 	Проширење Silvera-е захтева да се дода одређена подршка код прављења самих модела. Та подршка је заправо коришћење метакласе Plugin. Користи се као врста декларације највишег нивоа, равноправна  са већ постојећим декларацијама као што су domain, service, event и остали.  На слици 6.10.2:1 се може видети на који начин је Plugin додат у самој декларацији. Да би се користио Plugin додатаку потребно је за почетак да се дефинише идентитет. Дефинисање идентитета је заправо одређивање назива, верзије и описа. Након тога потребно је написати циљну платформу (target) која је у овом случају Azure. Затим је потребно да се одредити и врста (kind), да ли је у питању deployment или testing. Врста се у овом случају назива још и дискриминатором, јер од ње зависи који ће се ток даље преузети. У конкретном апликацији када се изабере да је kind = deployment, тада се одабере ток који креира семантички модел које омогућавају  пребацибање апликације на Azure.

 
#figure(image("../slike/slika-6.10.2-1.png", width: 90%), caption: [Дефинисање Plugin у коду])

На слици 6.10.2:2 су приказане семантички модел DeploymentTarget који омогућава пребацивање апликације на Azure. Oва класа се даље грана на ServiceDeployment, она носи CPU, memory, min/max-replicas, назив апликације и референцира сервис из језгра. Логички сервис претвара у ресурс који се може покренути. Следећа метакласа је ContainerAppsEnv додавањем ове метакласе метамодел добија две алтернативне платформе, а изведено својство uses_container_apps бира између њих. То је у ужем смислу је подршка за Azure. Ingress је адреса сервиса и састоји се од порт и тачног излази с адресама. Без тога испоручен систем нема објављену адресу, па се не може ни позвати ни проверити. Како се то види у синтакси је на слици 6.10.2:2.


 
#figure(image("../slike/slika-6.10.2-2.png", width: 90%), caption: [Синтаксни приказ метамодела])


На слици  6.10.2:3 је приказано како се то види у коду

 
#figure(image("../slike/slika-6.10.2-3.png", width: 90%), caption: [Приказ метамодела за деполјмент у коду])

 	Закључак је да проширење додаје језгру језика тачно једну метакласу Plugin, а сву платформску сложеност смешта иза њеног дискриминатора. Тиме основни Silvera модел остаје платформски независан, док пребацивање апликације и тестирање постају прворазредни, проверљиви делови модела уместо пратећих скрипти које се тихо разилазе са системом који описују.


6.10.3	Генерисање Azure конфигурације и пребацивање сервиса на Azure

Да би било омогућено да се Azure конфигурација изгенерише уз помоћ Silvera-е, потребно је да постоји .si фајл за почетак. У конкретном случају ове апликације назван је azure-deployment.si и представља Silvera модел, од кога ће настати све оно то је потребно за пребацивање апликације на Azure.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу azure-deployment.si  су дефинисане следеће ствари resource-group, container-registry, container-apps-environment, database, messaging, key-vault, service-deployments, ingress,monitoring. 

Како би пребацивање на Azure било могућ потребно је да постоји претходно креиран налог, који има одређене претплате које подржавају покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату Azure за студенте   и добила 100 долара бесплатног кредита који могу да користим. Када постоји креиран налог са активном претплатом потребно је да се одради команда az acr login, након ње docker compose build. На слици 6.10.3:1 се види како то све изгледа након успешног пребацивања апликације на Azure-у. Све ово је смештено у оквиру order-tracking-rg ресурс групе.

 
#figure(image("../slike/slika-6.10.3-1.png", width: 90%), caption: [Ресурси order-tracking-rg групе])
Поставка за Kubernetes сервисе је на слици 6.10.3:2. 
#figure(image("../slike/slika-6.10.3-2.png", width: 90%), caption: [Kubernetes сервис])


Укупан трошак ових сервиса за последњих три месеца је приказан на слици 6.10.3:3.
 
#figure(image("../slike/slika-6.10.3-3.png", width: 90%), caption: [Преглед трошкова за три месеца])
Сви сервиси су смештени у оквиру Kubernetes сервиса order-tracking-aks, јер је то био једноставнији начин како би се покретање свих сервиса уклопило у претплату за Azurе налог који користим. Преглед тога видљив је на слици 6.10.3:4.

 
#figure(image("../slike/slika-6.10.3-4.png", width: 90%), caption: [Ресурси order-tracking-aks групе])

6.10.4	Тестирање имплементираног решења на Azure платоформи

Јако је битно да постоји одређен начин провере рада сервиса након што се апликација и њени сервиси пребаце на Azure. Апликација за обраду поруџбине, која је описана у овом мастер раду,  има један део тестова генерисаних помоћу Silvera-е, док је један део писан ручно. Ручно писани су такозвани smoke тестови. Не постоји разлика између генерисаних тестова за Azure и  AWS,  ради се на исти начин. 

Сам приступ за генерисање тестова, другачији функционише од већ описаних процеса за фајлове међу којима су services.si, events.si, communication.si, entities.si. У оквиру ових фајлова постоји додатак који генератор test_generator.py користи и уз помоћ Jinja шаблона штампа се као стварни Python код, помоћу кога се ствара прави Python фајл. Тестови који су изгенерисани и који су смештени у tests/generated/ су api_surface.py, ту имамо чисте податке, међу којима је листа свих рута и топологија догађаја. Изгенерисан тест test_auth_enforcement.py тестира јавне руте, тестира руте без токена и са неважећим токеном, има и тест примери који покривају када се приступа са исправним токеном. Тест test_jwt_hardening.py испитује токене по сервису, тест test_messaging.py је задужен за испитивање порука. Што се самих догађаја тиче, покривени су тестовима тако што се проверава да ли постоји RabbitMQ exchange за сваки догађај који неко користи, проверавају се да ли за сваки модел за који треба да постоје редови везани за exchange заправо постоје. Битно је да се види да ли сваки ред има бар једног активног consumer-а и да ли је durable (ако модел то тражи), да ли dead-letter ред постоји тамо где је декларисан и бави се пријављивањем "orphan" догађаје на информативном нивоу. Ручно писани тестови су smoke тестови и то је урађено из разлога што су то тестови којима се тестира имплементаиција, а не сам ЈСД модел.

Тестови се покрећу из локала и постоје одређени кораци који требају бити испуњени како би се покренули. Ако се приступа из терминала потребно је прво да се осигура аутентификација са Azure  налогом коришћењем команди:

& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" login --tenant tenantId
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" account set --subscription subscriptionId 
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" aks get-credentials --resource-group order-tracking-rg --name order-tracking-aks

Треба покренути сервисе, препорука је да се покрену у оквиру пет одвојена терминала следеће команде:

kubectl port-forward svc/order-service 8081:80 -n order-tracking
kubectl port-forward svc/payment-service 8082:80 -n order-tracking
kubectl port-forward svc/tracking-service 8083:80 -n order-tracking
kubectl port-forward svc/notification-service  8084:80 -n order-tracking
kubectl port-forward svc/rabbitmq 15672:15672 -n order-tracking

Како би утврдили да гађамо праве сервисе, потребно је прво проверити да не гађају тестови сервисе у локалу командом  docker ps која треба да врати празно. Следећи корак ове провере је да се узму идентификатори процеса који се одвијају у  Kubernetes-у следећом командом 

Get-NetTCPConnection -LocalPort 8081,8082,8083,8084 -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess

На слици 6.10.4:1 колона OwningProcess заправо представља бројеве који су идентификатори процеса

 
#figure(image("../slike/slika-6.10.4-1.png", width: 90%), caption: [Приказ идентификатора процеса])

На слици 6.10.4:12 имамо приказ тих процеса

 
#figure(image("../slike/slika-6.10.4-2.png", width: 90%), caption: [Приказ покренутих процеса у терминалу])

Када имамо све проверено на овај начин, осигурано је да покренути тестови се извршавају на Azure платформи. Покретање тестова се врши тако што се прво навигира до директоријума где се налазе тестови, а затим покрену следећим комаднама

python tests\generated\test_auth_enforcement.py
python tests\generated\test_jwt_hardening.py
python tests\generated\test_messaging.py
python tests\smoke_test.py


Резултати покретања test_auth_enforcement.py тестова:

Section 1 — Public endpoints  (no token required)
─────────────────────────────────────
  [PASS] OrderService           GET    /health   (orders-db, rabbitmq)
  [PASS] OrderService           GET    /health/ready   (orders-db, rabbitmq)
  [PASS] PaymentService         GET    /health   (payments-db, rabbitmq)
  [PASS] PaymentService         GET    /health/ready   (payments-db, rabbitmq)
  [PASS] TrackingService        GET    /health   (rabbitmq, tracking-db)
  [PASS] TrackingService        GET    /health/ready   (rabbitmq, tracking-db)
  [PASS] NotificationService    GET    /health   (notifications-db, rabbitmq)
  [PASS] NotificationService    GET    /health/ready   (notifications-db, rabbitmq)
───────────────────────────────────────
  Section 2 — Missing token  (every [auth-required] route → 401)
───────────────────────────────────────
  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/4d24f7d7-637c-4f49-9fcb-5c6a9c020752
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/e39e0dad-95e8-4c42-8b6d-e9201928c38a/status
  [PASS] OrderService           DELETE /api/v1/orders/b16f5af4-2ad0-4c83-beca-dacd2f05a1ad
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/c7118ffb-9196-475a-a9dd-cf889f8158a7
  [PASS] PaymentService         GET    /api/v1/payments/order/ba6a541c-c164-4107-aed2-c24322a11041
  [PASS] PaymentService         PUT    /api/v1/payments/ca9f3bda-3105-4ab9-a815-2cbe564b6881/status
  [PASS] PaymentService         POST   /api/v1/payments/938bfcd9-f53a-419d-9861-cef49b375241/refund
  [PASS] TrackingService        GET    /api/v1/tracking/b7902f76-8c10-4b64-b458-b5d3cb77ef7d
  [PASS] TrackingService        GET    /api/v1/tracking/84bfff3e-24c1-439a-8e10-fca5059ea77a/history
  [PASS] TrackingService        GET    /api/v1/tracking/bbf03030-3c8f-4c3f-b691-0724c26df622/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/775ce0d0-018c-4781-ac5e-69b87d2b8649
  [PASS] NotificationService    POST   /api/v1/notifications/resend/783d7e29-b29f-4804-9112-8f07db5b6bea
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

─────────────────────────────────
  Section 3 — Invalid token  (wrong signing key → 401)
─────────────────────────────────
  A service that only checks for the presence of an Authorization
  header passes Section 2 and fails here.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/3fb7c8e1-0c12-421e-b093-b43ef49bd381
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/a713d3ad-3135-49b2-bac4-3216228cd104/status
  [PASS] OrderService           DELETE /api/v1/orders/2ff2a456-8553-4c39-9a71-6af358e98984
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/4d164c1e-9ab1-41f0-bfbb-9c5c6c355100
  [PASS] PaymentService         GET    /api/v1/payments/order/b89e8ab3-3d70-4f15-a54c-8e7228e3d89d
  [PASS] PaymentService         PUT    /api/v1/payments/61c2ef8f-a45e-467f-ae5a-0330b44344bc/status
  [PASS] PaymentService         POST   /api/v1/payments/545e734f-f972-4a39-84b9-5d0eba903dbf/refund
  [PASS] TrackingService        GET    /api/v1/tracking/d3045927-133c-44ed-b6f6-7df3005be784
  [PASS] TrackingService        GET    /api/v1/tracking/71baefec-fdf7-429c-853a-be29ee6916ff/history
  [PASS] TrackingService        GET    /api/v1/tracking/cfb37419-1cc9-4b1f-a5a1-db08a1bf0945/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/74d1128e-26d7-4af7-b6bc-4d8b9a91041a
  [PASS] NotificationService    POST   /api/v1/notifications/resend/50cadc60-581e-4cbc-8e29-625d10befc0c
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────
  Section 4 — Control  (a valid token must NOT be rejected)
───────────────────────────────────
  One read per service. A 401 here means Sections 2 and 3 passed
  because everything is rejected, not because auth works.

  [PASS] OrderService           GET    /api/v1/orders/ebbf111f-1233-494c-9164-4211087380b4
  [PASS] PaymentService         GET    /api/v1/payments/b3b62577-9a17-4a4b-8431-729d19dc69c0
  [PASS] TrackingService        GET    /api/v1/tracking/d926fcae-206d-4b9d-a4ad-bd525eece07e
  [PASS] NotificationService    GET    /api/v1/notifications
---
                   Results:  48 passed  0 failed  0 skipped  (48 total)
---
Резултати покретања test_jwt_hardening.py:

  JWT Hardening — generated from silvera/services.si
  8 bad-token case(s) against 4 service(s)
---
──────────────────────────
  Sections 1–4 — Bad tokens must be refused
──────────────────────────
  OrderService   GET /api/v1/orders/f7d7b613-cfed-42a9-8d0b-8cda7d613411
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  PaymentService   GET /api/v1/payments/84c68b3e-04f3-464d-91d2-00f21ff26d59
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  TrackingService   GET /api/v1/tracking/c1d7396e-f737-4076-8ae2-df76ff53ec55
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  NotificationService   GET /api/v1/notifications
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

──────────────────────────────────
  Control — a correctly signed token must NOT be refused
──────────────────────────────────
  Without this, a service that is down or that rejects everything
  would look perfectly hardened.

  [PASS] OrderService           GET /api/v1/orders/71b95420-ed1e-4212-9a8c-7a62ad0b9784
  [PASS] PaymentService         GET /api/v1/payments/e7f27d8c-a59b-48df-a95a-784a06e85655
  [PASS] TrackingService        GET /api/v1/tracking/d9f32da2-e6a0-4d83-9354-d1df7cdad189
  [PASS] NotificationService    GET /api/v1/notifications
---
  Results:  36 passed  0 failed  0 skipped  (36 total)
---
Резултати покретања test_messaging.py тестова:

   Messaging topology — generated from silvera/communication.si
  5 consumed event(s), 8 receive endpoint(s), 1 orphan(s)
---
  Section 1 — Broker reachable
───────────────────────────
  [PASS] RabbitMQ management API /api/overview
         broker version 3.13.7

────────────────────────────────
  Section 2 — Exchanges  (one per consumed event)
────────────────────────────────
  [PASS] OrderCancelledEvent        exchange declared
  [PASS] OrderCreatedEvent          exchange declared
  [PASS] OrderStatusChangedEvent    exchange declared
  [PASS] PaymentFailedEvent         exchange declared
  [PASS] PaymentProcessedEvent      exchange declared

───────────────────────────────────────────
  Section 3 — Fan-out  (exactly the queues the model routes each event to)
───────────────────────────────────────────
  A missing entry means that subscriber never started. A shared one
  means subscribers compete and each event reaches only one of them.

  [PASS] OrderCancelledEvent        → NotificationService, PaymentService, TrackingService
  [PASS] OrderCreatedEvent          → NotificationService, PaymentService, TrackingService
  [PASS] OrderStatusChangedEvent    → NotificationService, TrackingService
  [PASS] PaymentFailedEvent         → NotificationService, OrderService, TrackingService
  [PASS] PaymentProcessedEvent      → NotificationService, OrderService, TrackingService

───────────────────────────────────────────
  Section 4 — Receive endpoints  (the queues the subscription blocks name)
───────────────────────────────────────────
  [PASS] payment-service.order-created          OrderCreatedEvent
  [PASS] payment-service.order-cancelled        OrderCancelledEvent
  [PASS] order-service.payment-processed        PaymentProcessedEvent
  [PASS] order-service.payment-failed           PaymentFailedEvent
  [PASS] tracking-service.order-events          OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] tracking-service.payment-events        PaymentProcessedEvent, PaymentFailedEvent
  [PASS] notification-service.order-events      OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] notification-service.payment-events    PaymentProcessedEvent, PaymentFailedEvent

─────────────────────────────────────────
  Section 5 — Dead-letter queues  (targets named by dead-letter { })
─────────────────────────────────────────
  [PASS] dlq.payment-service.order-created          ← payment-service.order-created
  [PASS] dlq.payment-service.order-cancelled        ← payment-service.order-cancelled
  [PASS] dlq.order-service.payment-processed        ← order-service.payment-processed
  [PASS] dlq.order-service.payment-failed           ← order-service.payment-failed
  [PASS] dlq.tracking-service.order-events          ← tracking-service.order-events
  [PASS] dlq.tracking-service.payment-events        ← tracking-service.payment-events
  [PASS] dlq.notification-service.order-events      ← notification-service.order-events
  [PASS] dlq.notification-service.payment-events    ← notification-service.payment-events

─────────────────────────────────────────
  Section 6 — Orphan events  (informational)
─────────────────────────────────────────
  Published by a service, consumed by none. Nothing binds them, so
  the exchange may not exist at all. Not a broker fault — either a
  subscriber is missing from the model, or the event is dead weight.

  [SKIP] PaymentRefundedEvent       published by PaymentService, no subscribers
---
  Results:  27 passed  0 failed  1 skipped  (28 total)
---
Резултати smoke тестова су представљени на овај начин: 


  Order Tracking System — Integration Test Suite
  Mode: local   Section: all
---
  Section 1 — Health checks  (AddNpgSql registered → 'Healthy' = DB reachable)
──────────────────────────────────────────────────
  [PASS] OrderService           /health
  [PASS] OrderService           /health/ready
  [PASS] PaymentService         /health
  [PASS] PaymentService         /health/ready
  [PASS] TrackingService        /health
  [PASS] TrackingService        /health/ready
  [PASS] NotificationService    /health
  [PASS] NotificationService    /health/ready

───────────────────────────────────────────────────
  Section 2 — Auth enforcement  (every method, expect HTTP 401 without JWT)
───────────────────────────────────────────────────
  Driven by tests/generated/api_surface.py — every [auth-required]
  endpoint in silvera/services.si, including the mutating ones
  (POST/PUT/DELETE) where a missing [Authorize] matters most.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/d8e1600a-ace4-4a2c-bdde-85d924b3563a
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/829d829f-0976-4933-9fe9-c4f9fc912553/status
  [PASS] OrderService           DELETE /api/v1/orders/913ad841-8580-410e-9b8a-b948100fde5a
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/f3648747-2c26-44cb-9210-7da752d3bf5f
  [PASS] PaymentService         GET    /api/v1/payments/order/e5421a90-eaad-4de5-b1e2-b881b61798bf
  [PASS] PaymentService         PUT    /api/v1/payments/d7eb6230-b006-4f65-b840-d0f2d8a8664a/status
  [PASS] PaymentService         POST   /api/v1/payments/65dc30a9-5e04-4c9c-a990-151e8051c312/refund
  [PASS] TrackingService        GET    /api/v1/tracking/46d5eb76-cf66-4de6-b750-fedad4c7746b
  [PASS] TrackingService        GET    /api/v1/tracking/fa1c4b4c-f8bd-4b96-979f-71d2e5c49e3d/history
  [PASS] TrackingService        GET    /api/v1/tracking/5deca6ef-c34e-4343-8875-5396f5b2d920/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/637bb50c-78de-411f-911c-bcdeaca7e9d3
  [PASS] NotificationService    POST   /api/v1/notifications/resend/453544ce-f02d-4a7d-8038-70bb8a6eabb1
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────────────
  Section 3 — Authenticated reads + JSON schema validation
────────────────────────────────────────────

  3a. List endpoints — expect 200 with empty PagedResult
  [PASS] OrderService           GET /api/v1/orders?customerId=71ba3512-92be-405c-
  [PASS] PaymentService         GET /api/v1/payments/order/71ba3512-92be-405c-ba8
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd34
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd34
  [PASS] NotificationService    GET /api/v1/notifications
  [PASS] NotificationService    GET /api/v1/templates

  3b. Get-by-ID — expect 404 for unknown UUID
  [PASS] OrderService           GET /api/v1/orders/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] PaymentService         GET /api/v1/payments/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] NotificationService    GET /api/v1/notifications/71ba3512-92be-405c-ba8f-dd3470e581e2
  [PASS] TrackingService        GET /api/v1/tracking/71ba3512-92be-405c-ba8f-dd3470e581e2/status

  3c. Pagination field values on OrderService list
  [PASS]   OrderService         page == 1
  [PASS]   OrderService         pageSize == 5
  [PASS]   OrderService         totalCount == 0
  [PASS]   OrderService         items == []

────────────────────────────────────────────
  Section 4 — Messaging infrastructure  (RabbitMQ management API)
────────────────────────────────────────────
  [PASS] RabbitMQ management API /api/overview
  [PASS] Response contains rabbitmq_version field
  [PASS] RabbitMQ exchanges present (22 found, 21 named)
  [PASS] An exchange exists for all 5 event types
  [PASS] RabbitMQ queues visible (16 queues — services connected if > 0)
  [PASS] Every queue is one the model names (16 expected)
  [PASS] All 8 receive endpoints exist
  [PASS] No orphaned queues (every consumer queue has a live consumer)
  [PASS] No messages in the model's dead-letter queues
  [PASS] No messages in MassTransit _error queues (no faulting consumers)
  [PASS] No messages in _skipped queues (no unroutable/dead messages)
  [PASS] All 4 services have active AMQP connections (4 connections found)

───────────────────────────────────────────
  Section 5 — Stub behaviour  (POST endpoints still unimplemented)
───────────────────────────────────────────
  OrderService's mapping stubs are implemented, so POST /api/v1/orders
  is covered by Section 6 instead. PaymentService still throws
  NotImplementedException from MapToRequest(); 400 = model binding
  rejected the empty body first. Both mean routing + auth worked.

  [PASS] PaymentService         POST /api/v1/payments

───────────────────────────────────────────
  Section 6 — End-to-end event flow  (publish → consume → persisted)
───────────────────────────────────────────
  [PASS] OrderService  POST /api/v1/orders → 201
  [PASS] Order total computed from line items (got 124.0, expected 124.00)

  waiting 8s for the event to propagate…
  [PASS] TrackingService  consumed OrderCreatedEvent (TrackingRecord written)
  [PASS] TrackingService  OrderTimeline snapshot updated
  [PASS] NotificationService  consumed the SAME event (fan-out, not competing)
  [PASS] OrderService  PUT /status → 200 (publishes OrderStatusChangedEvent)
  [PASS] TrackingService  timeline advanced to 2 events (expected >= 2)

──────────────────────────────────────
  Section 7 — Full API surface  (GET / POST / PUT / DELETE)
──────────────────────────────────────
  [PASS] Seed  POST /api/v1/orders → 201

  waiting 8s for consumers to populate tracking…

  [PASS] OrderService           GET    /api/v1/orders                             list by customer
  [PASS] OrderService           GET    /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3 get seeded order
  [PASS] OrderService           GET    /api/v1/orders/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] OrderService           PUT    /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3/status status transition
  [PASS] OrderService           DELETE /api/v1/orders/c53c7e77-23a1-4675-8b88-4195955124e3 cancel order
  [PASS] PaymentService         GET    /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] PaymentService         GET    /api/v1/payments/order/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 empty list, no mapping
  [PASS] PaymentService         POST   /api/v1/payments                           MapToRequest stub
  [PASS] PaymentService         PUT    /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/status stub / KeyNotFound
  [PASS] PaymentService         POST   /api/v1/payments/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/refund MapToRequest stub
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3 timeline records
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3/history history
  [PASS] TrackingService        GET    /api/v1/tracking/c53c7e77-23a1-4675-8b88-4195955124e3/status timeline snapshot
  [PASS] TrackingService        GET    /api/v1/tracking/fd710d28-0a62-4452-9c5d-66f2d2fb4b69/status untracked order → 404
  [PASS] NotificationService    GET    /api/v1/notifications                      list
  [PASS] NotificationService    GET    /api/v1/notifications/9fb7d9b0-768a-4979-8da4-e6d6d9450a77 get by id
  [PASS] NotificationService    GET    /api/v1/notifications/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 unknown id → 404
  [PASS] NotificationService    GET    /api/v1/templates                          list templates
  [PASS] NotificationService    POST   /api/v1/templates                          create
  [PASS] NotificationService    POST   /api/v1/notifications/resend/fd710d28-0a62-4452-9c5d-66f2d2fb4b69 resend

  [PASS] NotificationService    verbs exercised: GET, POST
  [PASS] OrderService           verbs exercised: DELETE, GET, PUT
  [PASS] PaymentService         verbs exercised: GET, POST, PUT
  [PASS] TrackingService        verbs exercised: GET
  [PASS] All four HTTP verbs exercised across the system

───────────────────────────────────
  Section 8 — Data integrity  (round-trip + business rules)
────────────────────────────────────

  8a. POST then GET — every field must survive the round-trip
  [PASS] round-trip customerId
  [PASS] round-trip currency
  [PASS] round-trip notes
  [PASS] round-trip item count
  [PASS] round-trip shippingAddress (owned entity persisted)
  [PASS] round-trip line items (name / quantity / unitPrice)
  [PASS] totalAmount derived from items (124.00)
  [PASS] new order starts in PENDING

  8b. DELETE an order, then confirm tracking learned about it
  [PASS] DELETE /api/v1/orders/{id} → 204
  [PASS] cancelled order persists with status CANCELLED
  [PASS] TrackingService reflects the cancellation (cross-service consistency)

  8c. Pagination — page 1 and page 2 must differ
  [PASS] totalCount reports 3 seeded orders
  [PASS] page 1 returns pageSize=2 items
  [PASS] page 2 returns the remaining 1 item
  [PASS] pages do not overlap (real slicing, not the same rows twice)
  [PASS] totalPages computed correctly

───────────────────────────────────────────
  Section 9 — JWT hardening  (bad tokens must be rejected)
──────────────────────────────────────────
  [PASS] rejected: expired token (exp in the past)
  [PASS] rejected: wrong issuer
  [PASS] rejected: wrong audience
  [PASS] rejected: signed with the wrong key
  [PASS] rejected: valid claims, tampered signature
  [PASS] rejected: malformed token
  [PASS] rejected: empty bearer value
  [PASS] control: a correctly signed token is still accepted
---
  Results:  110 passed  0 failed  0 skipped  (110 total)
  All checks passed.
---
Тестови који су креирани за проверу рада ове апликације су важан део процеса. Омогућавају проверу исправности комуникације између различитих сервиса и понашања система у реалном окружењу. Извршавају се локално, док истовремено комуницирају са сервисима који су пребачени на Azure Kubernetes Service (AKS). Тестови служе као превенција, односно да се раније открију проблеми у комуникацији, конфигурацији и интеграцији сервиса открију пре пуштања апликације у продукционо окружење. 

 

6.11	Проширење Silvera-е подршком за деплојмент и тестирање на AWS платформи

Amazon Web Services (AWS) једно јако популарно окружење у облаку које се користи за развој и извршавање микросервисних апликација. Развила га је компанија Amazon . AWS пружа велики број сервиса које покривају готово све области развоја и одржавања апликација, укључујући рачунарске ресурсе, као што су виртуелне машине, контејнере и serverless функције, затим складиштење података, базе података, мрежне сервисе, безбедност и управљање приступом, вештачку интелигенцију и аналитику. Једна од највећих предности AWS-а је скалабилност, односно могућност повећања или смањења ресурса у складу са тренутним потребама апликације. Поред тога, AWS користи модел плаћања по потрошњи (pay-as-you-go), што значи да корисници плаћају само оне ресурсе које су заиста користили. 


6.11.1	Проширење метамодела и синтаксе

Идентична прича која је постојала као и за Azure, потребно је да се прошири Silvera-е и то је учињено на начин да се да додатна подршка код прављења самих модела. Та подршка је заправо коришћење метакласе Plugin. Као и раније што је поменуто, да би се користио Plugin додатак потребно је за почетак да се дефинише идентитет. Дефинисање идентитета је заправо одређивање назива, верзије и описа. Након тога потребно је написати циљну платформу (target) која је у овом случају AWS. Затим је потребно да се одредити и врста (kind), да ли је у питању deployment или testing. Врста се у овом случају назива још и дискриминатором, јер од ње зависи који ће се ток даље преузети. У конкретном апликацији када се изабере да је kind = deployment, тада се одабере ток који креира метакласе које омогућавају  пребацивање апликације на AWS. 

Семантички модел који омогућава пребацивање апликације на AWS је DeploymentTarget.

#figure(
  raw("name = 'AwsEc2Deployment'\\ntarget = 'aws-ec2'\\nregion = 'us-east-1'\\napp_name = 'order-tracking'\\ninstance_type = 't3.micro'\\ndisk_gb = 30\\nswap_gb = 6\\nallowed_ssh_cidr = '0.0.0.0/0'\\nallowed_app_cidr = '0.0.0.0/0'\\nmessaging_type = 'rabbitmq-container'\\nmessaging_mgmt_port = 15672", lang: "text"),
  caption: [Дефинисање AWS deployment модела],
)


6.11.2	Генерисање AWS конфигурације и пребацивање сервиса на AWS

Silvera модел који је задужен за генерисање AWS конфигурација је aws-ec2-deployment.si.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу aws-ec2-deployment.si  су дефинисане ствари које су потребне да буду подржане за креирање Terraform скрипти. Има следеће информације version, description, target, provider, compute, messaging. 

Како би пребацивање на AWS било могуће потребно је да постоји претходно креиран налог који има одређене претплате које би омогућиле покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату AWS Free Tier   и имала сам могућност да добијем првих 100 долара бесплатног кредита који могу да користим наредна три месеца, уз одређена ограничења. AWS сервиси су поприлично скупи, па је било потребно да се обрати пажња да се изаберу неке јефтинија верзија, како се не би одмах потрошио читав кредит. Након што је све изгенерисано, потребно је да се покрену ове команде, да се дода кључ и тајна са AWS налога, на тај начин је омогућен приступ, након тога aws configure и након тога terraform apply.

 
#figure(image("../slike/slika-6.11.2-1.png", width: 90%), caption: [Приказ EC2 инстанци])

 
#figure(image("../slike/slika-6.11.2-2.png", width: 90%), caption: [Детаљан order-tracking-sg приказ ресурса])

 
6.11.3	Тестирање имплементираног решења на AWS платформи

 	Као што је већ споменуто генерисање тестова за Azure и AWS се одвија на исти начин, јер је су фајлови services.si, events.si, communication.si, entities.si где се налазе Silvera модели проширени како би подржали генерисање тестова. Овде су такође smoke тестови ручно направљени из истих разлога, јер се њима тестира сама имплементација, а не сами ЈСД модели. Детаљније о самим тестовима и њиховом дефинисању у оквиру апликације налази се у поглављу  6.10.4 Тестирање имплементираног решења на Azure платоформи. Пошто су исти тестови, како би тестирали њихово понашање на различитим платформама, битан је начин на који се све ово покреће. Међу првим корацима је то да се преко терминала улогује на одговарајући AWS налог, где су постављени сервиси. Потребно је покренути команде, чији излаз бу требао да буде running 3.84.174.154

aws ec2 describe-instances --instance-ids i-076084e187740f8e0 --region us-east-1 ` --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" --output text


Проверити да ли се овде враћа као статус health, за следеће команде

curl http://3.84.174.154:8081/health
curl http://3.84.174.154:8082/health
curl http://3.84.174.154:8083/health
curl http://3.84.174.154:8084/health

Команде за покретање тестова су:

 	python test_auth_enforcement.py `
--order-service-url http://3.84.174.154:8081 `
--payment-service-url http://3.84.174.154:8082 `
--tracking-service-url http://3.84.174.154:8083 `
--notification-service-url http://3.84.174.154:8084

python test_messaging.py --broker-url http://3.84.174.154:15672 --broker-user guest --broker-password guest

python test_jwt_hardening.py `
--order-service-url http://3.84.174.154:8081 `
   --payment-service-url http://3.84.174.154:8082 `
--tracking-service-url http://3.84.174.154:8083 `
--notification-service-url http://3.84.174.154:8084
&  "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" tests/smoke_test.py 
       -- mode aws `
       --order-url http://3.84.174.154:8081 `
       --payment-url http://3.84.174.154:8082 `
       --tracking-url http://3.84.174.154:8083 `
        --notification-url http://3.84.174.154:8084 `
 --rabbitmq-url http://3.84.174.154:15672

Резултати када се покрену тестови из test_auth_enforcement.py


  Auth Enforcement — generated from silvera/services.si
  18 protected / 8 public endpoints across 4 services
---
  OrderService           http://3.84.174.154:8081
  PaymentService         http://3.84.174.154:8082
  TrackingService        http://3.84.174.154:8083
  NotificationService    http://3.84.174.154:8084

─────────────────────────────────
  Section 1 — Public endpoints  (no token required)
─────────────────────────────────
  [PASS] OrderService           GET    /health   (orders-db, rabbitmq)
  [PASS] OrderService           GET    /health/ready   (orders-db, rabbitmq)
  [PASS] PaymentService         GET    /health   (payments-db, rabbitmq)
  [PASS] PaymentService         GET    /health/ready   (payments-db, rabbitmq)
  [PASS] TrackingService        GET    /health   (rabbitmq, tracking-db)
  [PASS] TrackingService        GET    /health/ready   (rabbitmq, tracking-db)
  [PASS] NotificationService    GET    /health   (notifications-db, rabbitmq)
  [PASS] NotificationService    GET    /health/ready   (notifications-db, rabbitmq)

──────────────────────────────────────
  Section 2 — Missing token  (every [auth-required] route → 401)
──────────────────────────────────────
  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/3910dabe-a534-4079-9264-21c0d2783de7
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/655ac7df-54e4-4504-a4a2-ecdfd79484cb/status
  [PASS] OrderService           DELETE /api/v1/orders/94d7cff4-90d0-4f0d-a328-51773a3eaa35
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/bb5c9e37-b6a5-48ea-952d-6fbcec71f6f8
  [PASS] PaymentService         GET    /api/v1/payments/order/d1476676-5f7c-4ab8-8d76-e585348a0436
  [PASS] PaymentService         PUT    /api/v1/payments/8c202a4f-09b5-4c15-aa0c-474310b6d23d/status
  [PASS] PaymentService         POST   /api/v1/payments/f7436a9a-7ed4-4d48-b1f6-146cf5b200e2/refund
  [PASS] TrackingService        GET    /api/v1/tracking/cdc29b4c-3097-4e93-b7bc-ab63aac99343
  [PASS] TrackingService        GET    /api/v1/tracking/15f9349a-602c-4cf0-982a-4543b8a221dd/history
  [PASS] TrackingService        GET    /api/v1/tracking/0879205d-5f6f-4b77-9e61-7cc55c977f58/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/96dde481-2ee9-4940-a860-6d59a1e3e963
  [PASS] NotificationService    POST   /api/v1/notifications/resend/c1c3a80b-470e-44ef-ac08-d7fea221edd1
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

─────────────────────────────────
  Section 3 — Invalid token  (wrong signing key → 401)
─────────────────────────────────
  A service that only checks for the presence of an Authorization
  header passes Section 2 and fails here.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/f18a82e5-fe1e-482d-8a40-101d54c89828
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/e9fabc13-d0be-45d4-9f06-4a261e5808cc/status
  [PASS] OrderService           DELETE /api/v1/orders/62c6f0a3-5a31-471d-884f-6a1cb71651b2
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/f5b4a6ec-688e-4764-b968-9de9dc87e738
  [PASS] PaymentService         GET    /api/v1/payments/order/7cb719e9-c927-4273-ac53-0eb2e3a88c0c
  [PASS] PaymentService         PUT    /api/v1/payments/fe99d4a0-7707-4f1b-b1c0-45c3feaed156/status
  [PASS] PaymentService         POST   /api/v1/payments/33eedee8-3136-463b-8a81-048422af1302/refund
  [PASS] TrackingService        GET    /api/v1/tracking/c54ccffb-22d2-4991-8a73-6b39ad25f119
  [PASS] TrackingService        GET    /api/v1/tracking/de0cbbbd-6f1c-4638-81f1-4e0f72637f6c/history
  [PASS] TrackingService        GET    /api/v1/tracking/9c3e0e15-b1eb-45d3-a0d8-d75ccc1509f3/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/d29e20cc-dbb0-473e-b970-1c853ad03f90
  [PASS] NotificationService    POST   /api/v1/notifications/resend/c94c9071-914d-458f-b865-a76f8cb4c8f5
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

───────────────────────────────────
  Section 4 — Control  (a valid token must NOT be rejected)
───────────────────────────────────
  One read per service. A 401 here means Sections 2 and 3 passed
  because everything is rejected, not because auth works.

  [PASS] OrderService           GET    /api/v1/orders/6bfd7602-48f2-4886-b6ab-f672086e9454
  [PASS] PaymentService         GET    /api/v1/payments/3a5cae11-0e5e-4d33-8896-15fd014e2f66
  [PASS] TrackingService        GET    /api/v1/tracking/982648f0-04d2-4333-95bf-6f4c44e71146
  [PASS] NotificationService    GET    /api/v1/notifications
---
  Results:  48 passed  0 failed  0 skipped  (48 total)
---
Резултати када се покрену тестови из test_messaging.py
                                         
  Messaging topology — generated from silvera/communication.si                                                
  5 consumed event(s), 8 receive endpoint(s), 1 orphan(s)
  Broker: http://3.84.174.154:15672
---
  Section 1 — Broker reachable
───────────────────
  [PASS] RabbitMQ management API /api/overview
         broker version 3.13.7

────────────────────────────────
  Section 2 — Exchanges  (one per consumed event)
───────────────────────────────
  [PASS] OrderCancelledEvent        exchange declared
  [PASS] OrderCreatedEvent          exchange declared
  [PASS] OrderStatusChangedEvent    exchange declared
  [PASS] PaymentFailedEvent         exchange declared
  [PASS] PaymentProcessedEvent      exchange declared

────────────────────────────────────────────
  Section 3 — Fan-out  (exactly the queues the model routes each event to)
────────────────────────────────────────────
  A missing entry means that subscriber never started. A shared one
  means subscribers compete and each event reaches only one of them.

  [PASS] OrderCancelledEvent        → NotificationService, PaymentService, TrackingService
  [PASS] OrderCreatedEvent          → NotificationService, PaymentService, TrackingService
  [PASS] OrderStatusChangedEvent    → NotificationService, TrackingService
  [PASS] PaymentFailedEvent         → NotificationService, OrderService, TrackingService
  [PASS] PaymentProcessedEvent      → NotificationService, OrderService, TrackingService

────────────────────────────────────────────
  Section 4 — Receive endpoints  (the queues the subscription blocks name)
────────────────────────────────────────────
  [PASS] payment-service.order-created          OrderCreatedEvent
  [PASS] payment-service.order-cancelled        OrderCancelledEvent
  [PASS] order-service.payment-processed        PaymentProcessedEvent
  [PASS] order-service.payment-failed           PaymentFailedEvent
  [PASS] tracking-service.order-events          OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] tracking-service.payment-events        PaymentProcessedEvent, PaymentFailedEvent
  [PASS] notification-service.order-events      OrderCreatedEvent, OrderStatusChangedEvent, OrderCancelledEvent
  [PASS] notification-service.payment-events    PaymentProcessedEvent, PaymentFailedEvent

────────────────────────────────────────
  Section 5 — Dead-letter queues  (targets named by dead-letter { })
────────────────────────────────────────
  [PASS] dlq.payment-service.order-created          ← payment-service.order-created
  [PASS] dlq.payment-service.order-cancelled        ← payment-service.order-cancelled
  [PASS] dlq.order-service.payment-processed        ← order-service.payment-processed
  [PASS] dlq.order-service.payment-failed           ← order-service.payment-failed
  [PASS] dlq.tracking-service.order-events          ← tracking-service.order-events
  [PASS] dlq.tracking-service.payment-events        ← tracking-service.payment-events
  [PASS] dlq.notification-service.order-events      ← notification-service.order-events
  [PASS] dlq.notification-service.payment-events    ← notification-service.payment-events

─────────────────────────────
  Section 6 — Orphan events  (informational)
─────────────────────────────
  Published by a service, consumed by none. Nothing binds them, so
  the exchange may not exist at all. Not a broker fault — either a
  subscriber is missing from the model, or the event is dead weight.

  [SKIP] PaymentRefundedEvent       published by PaymentService, no subscribers
---
  Results:  27 passed  0 failed  1 skipped  (28 total)
---
Резултати када се покрену тестови из jwt_hardening.py

  JWT Hardening — generated from silvera/services.si
  8 bad-token case(s) against 4 service(s)
---
  Sections 1–4 — Bad tokens must be refused
──────────────────────────────

  OrderService   GET /api/v1/orders/36605b51-c820-4500-a494-05fe1307ec7b
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  PaymentService   GET /api/v1/payments/d8fe7711-e6f7-4f7e-92f6-75dbc672e29a
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  TrackingService   GET /api/v1/tracking/d1bad770-6681-46c9-96d7-9717a42df82d
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

  NotificationService   GET /api/v1/notifications
  [PASS]   refused: expired (exp in the past)
  [PASS]   refused: wrong issuer
  [PASS]   refused: wrong audience
  [PASS]   refused: signed with the wrong key
  [PASS]   refused: valid claims, tampered signature
  [PASS]   refused: malformed token
  [PASS]   refused: empty bearer value
  [PASS]   refused: Basic scheme instead of Bearer

───────────────────────────────────
  Control — a correctly signed token must NOT be refused
─────────────────────────────────────
  Without this, a service that is down or that rejects everything
  would look perfectly hardened.

  [PASS] OrderService           GET /api/v1/orders/48ff5f9d-70e7-4596-b2ae-52da8e2aab4c
  [PASS] PaymentService         GET /api/v1/payments/cff9967d-c0fc-4063-8ca0-3df4fa5d81be
  [PASS] TrackingService        GET /api/v1/tracking/45cc542a-1236-4b57-a87f-837394e899cf
  [PASS] NotificationService    GET /api/v1/notifications
---
  Results:  36 passed  0 failed  0 skipped  (36 total)
---
Резултати када се покрену smoke тестови
 
Order Tracking System — Integration Test Suite
  Mode: aws   Section: all
---
  Section 1 — Health checks  (AddNpgSql registered → 'Healthy' = DB reachable)
───────────────────────────────────────────────────
  [PASS] OrderService           /health
  [PASS] OrderService           /health/ready
  [PASS] PaymentService         /health
  [PASS] PaymentService         /health/ready
  [PASS] TrackingService        /health
  [PASS] TrackingService        /health/ready
  [PASS] NotificationService    /health
  [PASS] NotificationService    /health/ready

───────────────────────────────────────────────
  Section 2 — Auth enforcement  (every method, expect HTTP 401 without JWT)
───────────────────────────────────────────────
  Driven by tests/generated/api_surface.py — every [auth-required]
  endpoint in silvera/services.si, including the mutating ones
  (POST/PUT/DELETE) where a missing [Authorize] matters most.

  [PASS] OrderService           POST   /api/v1/orders
  [PASS] OrderService           GET    /api/v1/orders/12a287a4-7a0a-4911-bb5d-5fdd36aebb8b
  [PASS] OrderService           GET    /api/v1/orders
  [PASS] OrderService           PUT    /api/v1/orders/97d8583e-f5f9-4f46-8de2-4b7512658076/status
  [PASS] OrderService           DELETE /api/v1/orders/f92f48d4-9996-4dba-a240-a75ab902858f
  [PASS] PaymentService         POST   /api/v1/payments
  [PASS] PaymentService         GET    /api/v1/payments/8e6427a5-7cd2-46f0-ad00-0fa67dc14e15
  [PASS] PaymentService         GET    /api/v1/payments/order/2cb41413-b273-4dd4-8b65-5433a1a7cff2
  [PASS] PaymentService         PUT    /api/v1/payments/62e6d7a9-926f-4b3a-93ba-f192b913cff4/status
  [PASS] PaymentService         POST   /api/v1/payments/291108f2-bc4c-4d60-a2ec-6b0f53341c4d/refund
  [PASS] TrackingService        GET    /api/v1/tracking/15e4318a-0273-4a50-b8e6-4e16c77072be
  [PASS] TrackingService        GET    /api/v1/tracking/3a461daf-5119-41aa-8676-103d7d0e633b/history
  [PASS] TrackingService        GET    /api/v1/tracking/a8843e03-c508-4e1f-bfec-40dc55d576e9/status
  [PASS] NotificationService    GET    /api/v1/notifications
  [PASS] NotificationService    GET    /api/v1/notifications/d4fd8757-bad9-4de9-a02b-4dd02257d56c
  [PASS] NotificationService    POST   /api/v1/notifications/resend/1d23a677-b2ec-458c-a6f4-9bf96c8c9d28
  [PASS] NotificationService    GET    /api/v1/templates
  [PASS] NotificationService    POST   /api/v1/templates

────────────────────────────────────
  Section 3 — Authenticated reads + JSON schema validation
────────────────────────────────────

  3a. List endpoints — expect 200 with empty PagedResult
  [PASS] OrderService           GET /api/v1/orders?customerId=951b31d8-0a3c-469d-
  [PASS] PaymentService         GET /api/v1/payments/order/951b31d8-0a3c-469d-b19
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209
  [PASS] NotificationService    GET /api/v1/notifications
  [PASS] NotificationService    GET /api/v1/templates

  3b. Get-by-ID — expect 404 for unknown UUID
  [PASS] OrderService           GET /api/v1/orders/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] PaymentService         GET /api/v1/payments/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] NotificationService    GET /api/v1/notifications/951b31d8-0a3c-469d-b192-1209f2459d18
  [PASS] TrackingService        GET /api/v1/tracking/951b31d8-0a3c-469d-b192-1209f2459d18/status

  3c. Pagination field values on OrderService list
  [PASS]   OrderService         page == 1
  [PASS]   OrderService         pageSize == 5
  [PASS]   OrderService         totalCount == 0
  [PASS]   OrderService         items == []

─────────────────────────────────────────
  Section 4 — Messaging infrastructure  (RabbitMQ management API)
─────────────────────────────────────────
  [PASS] RabbitMQ management API /api/overview
  [PASS] Response contains rabbitmq_version field
  [PASS] RabbitMQ exchanges present (22 found, 21 named)
  [PASS] An exchange exists for all 5 event types
  [PASS] RabbitMQ queues visible (16 queues — services connected if > 0)
  [PASS] Every queue is one the model names (16 expected)
  [PASS] All 8 receive endpoints exist
  [PASS] No orphaned queues (every consumer queue has a live consumer)
  [PASS] No messages in the model's dead-letter queues
  [PASS] No messages in MassTransit _error queues (no faulting consumers)
  [PASS] No messages in _skipped queues (no unroutable/dead messages)
  [PASS] All 4 services have active AMQP connections (4 connections found)

─────────────────────────────────────────
  Section 5 — Stub behaviour  (POST endpoints still unimplemented)
─────────────────────────────────────────
  OrderService's mapping stubs are implemented, so POST /api/v1/orders
  is covered by Section 6 instead. PaymentService still throws
  NotImplementedException from MapToRequest(); 400 = model binding
  rejected the empty body first. Both mean routing + auth worked.

  [PASS] PaymentService         POST /api/v1/payments

──────────────────────────────────────────
  Section 6 — End-to-end event flow  (publish → consume → persisted)
──────────────────────────────────────────
  [PASS] OrderService  POST /api/v1/orders → 201
  [PASS] Order total computed from line items (got 124.0, expected 124.00)

  waiting 8s for the event to propagate…
  [PASS] TrackingService  consumed OrderCreatedEvent (TrackingRecord written)
  [PASS] TrackingService  OrderTimeline snapshot updated
  [PASS] NotificationService  consumed the SAME event (fan-out, not competing)
  [PASS] OrderService  PUT /status → 200 (publishes OrderStatusChangedEvent)
  [PASS] TrackingService  timeline advanced to 2 events (expected >= 2)

─────────────────────────────────────
  Section 7 — Full API surface  (GET / POST / PUT / DELETE)
──────────────────────────────────────
  [PASS] Seed  POST /api/v1/orders → 201

  waiting 8s for consumers to populate tracking…

  [PASS] OrderService           GET    /api/v1/orders                             list by customer
  [PASS] OrderService           GET    /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76 get seeded order
  [PASS] OrderService           GET    /api/v1/orders/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] OrderService           PUT    /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76/status status transition
  [PASS] OrderService           DELETE /api/v1/orders/560579cc-759e-4368-91f9-6651f7ed3d76 cancel order
  [PASS] PaymentService         GET    /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] PaymentService         GET    /api/v1/payments/order/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 empty list, no mapping
  [PASS] PaymentService         POST   /api/v1/payments                           MapToRequest stub
  [PASS] PaymentService         PUT    /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/status stub / KeyNotFound
  [PASS] PaymentService         POST   /api/v1/payments/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/refund MapToRequest stub
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76 timeline records
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76/history history
  [PASS] TrackingService        GET    /api/v1/tracking/560579cc-759e-4368-91f9-6651f7ed3d76/status timeline snapshot
  [PASS] TrackingService        GET    /api/v1/tracking/77bbfd9e-0c4f-4f8e-823d-114f76e385e2/status untracked order → 404
  [PASS] NotificationService    GET    /api/v1/notifications                      list
  [PASS] NotificationService    GET    /api/v1/notifications/6bb5a157-35c0-43f5-8eae-ebed9afa5d13 get by id
  [PASS] NotificationService    GET    /api/v1/notifications/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 unknown id → 404
  [PASS] NotificationService    GET    /api/v1/templates                          list templates
  [PASS] NotificationService    POST   /api/v1/templates                          create
  [PASS] NotificationService    POST   /api/v1/notifications/resend/77bbfd9e-0c4f-4f8e-823d-114f76e385e2 resend

  [PASS] NotificationService    verbs exercised: GET, POST
  [PASS] OrderService           verbs exercised: DELETE, GET, PUT
  [PASS] PaymentService         verbs exercised: GET, POST, PUT
  [PASS] TrackingService        verbs exercised: GET
  [PASS] All four HTTP verbs exercised across the system

───────────────────────────────────
  Section 8 — Data integrity  (round-trip + business rules)
───────────────────────────────────

  8a. POST then GET — every field must survive the round-trip
  [PASS] round-trip customerId
  [PASS] round-trip currency
  [PASS] round-trip notes
  [PASS] round-trip item count
  [PASS] round-trip shippingAddress (owned entity persisted)
  [PASS] round-trip line items (name / quantity / unitPrice)
  [PASS] totalAmount derived from items (124.00)
  [PASS] new order starts in PENDING

  8b. DELETE an order, then confirm tracking learned about it
  [PASS] DELETE /api/v1/orders/{id} → 204
  [PASS] cancelled order persists with status CANCELLED
  [PASS] TrackingService reflects the cancellation (cross-service consistency)

  8c. Pagination — page 1 and page 2 must differ
  [PASS] totalCount reports 3 seeded orders
  [PASS] page 1 returns pageSize=2 items
  [PASS] page 2 returns the remaining 1 item
  [PASS] pages do not overlap (real slicing, not the same rows twice)
  [PASS] totalPages computed correctly

─────────────────────────────────────
  Section 9 — JWT hardening  (bad tokens must be rejected)
─────────────────────────────────────
  [PASS] rejected: expired token (exp in the past)
  [PASS] rejected: wrong issuer
  [PASS] rejected: wrong audience
  [PASS] rejected: signed with the wrong key
  [PASS] rejected: valid claims, tampered signature
  [PASS] rejected: malformed token
  [PASS] rejected: empty bearer value
  [PASS] control: a correctly signed token is still accepted
---
  Results:  110 passed  0 failed  0 skipped  (110 total)
  All checks passed.
---
Тестови који се овде извршавају локално комуницирају са сервисима који су доступни на AWS EC2 инстанцама. Циљ је да покрију што већу функционалност и међусобну комуникацију сервиса у окружењу које је блиско реалном продукционом окружењу. Овим приступом се на једноставнији начин врши провера интеграције микросервисне апликације и представља једну од могућности за њено извршавање и тестирање у AWS облаку.
 
*/

