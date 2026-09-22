
= Генерисање инфраструктуре и постављање апликације

== Генерисање Docker конфигурације

 	Генерисање Docker фајлова у Silvera-и функционише на тај начин да имамо четири Dockerfile-a и један compose фајл. Dockerfile-ови иду кроз Jinja2 шаблон, док је compose укуцан као Python string. На слици @slika-6-3-3-1 је приказано како се по сервису од модела дође до Docker фајла

 

#figure(image("../slike/slika-6.3.3-1.png", width: 90%), caption: [Дијаграм који показује пут од модела до Docker фајла по сервису]) <slika-6-3-3-1>


	Docker фајлови у Silvera-и генеришу се по сервисима. Основни шаблон приказан је у листингу @listing-dockerfile-template; мењају се само `service.name` и `service.port`, у зависности од сервиса за који се генерише.

 
#figure(
	```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
EXPOSE {{ service.port }}

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
COPY ["src/SharedKernel/SharedKernel.csproj", "SharedKernel/"]
COPY ["src/{{ service.name }}/{{ service.name }}.csproj", "{{ service.name }}/"]
RUN dotnet restore "{{ service.name }}/{{ service.name }}.csproj"

COPY src/SharedKernel/ SharedKernel/
COPY src/{{ service.name }}/ {{ service.name }}/
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:{{ service.port }}
ENTRYPOINT ["dotnet", "{{ service.name }}.dll"]
	```
	, caption: [Шаблон за прављење Docker фајлова по сервисима],
) <listing-dockerfile-template>



== Генерисање Terraform и Kubernetes конфигурације

У оквиру Silvera-е главни део модела за Terraform је написан у `aws-deployment.si` и `azure-deployment.si` фајловима. Унутар ових фајлова је дефинисано како да се направи све што је потребно за AWS/Azure налог, затим регистровање контејнера и Kubernetes кластера, дефинисање базе, начина слања порука, мониторинг и потребан фајл у коме се чувају скривене битне информације везане за базу и сервисе. Након генерисања апликације добијају се два одвојена фолдера за AWS и Azure, који имају исту структуру. Структура је приказана у листингу @listing-6-9-1.

 
#figure(
	```text
generated/
├── aws/
│   ├── main.tf.j2
│   ├── messaging.tf.j2
│   ├── secrets.tf.j2
│   └── terraform.tfvars.example.j2
└── azure/
		├── main.tf.j2
		├── messaging.tf.j2
		├── secrets.tf.j2
		└── terraform.tfvars.example.j2
	```
	, caption: [Структура фолдера за AWS и Azure],
) <listing-6-9-1>

	На слици @slika-6-9-2 је описано како тече сам процес генерисања свих фајлова који су неопходни Terraform-у. 
 
#figure(image("../slike/slika-6.9-2.png", width: 90%), caption: [Структура фајлова за Terraform]) <slika-6-9-2>
Што се тиче самог Kubernetes-а, погодан је алат за апликацију која треба да аутоматизује процес пребацивања апликације у облак, јер, ако се све правилно постави на почетку, нема потребе за додатним интервенцијама и ручним подешавањима. Кључну улогу у генерисању Kubernetes манифеста има функција `generate_k8s_manifests`, која се налази у оквиру датотеке `kubernetes_generator.py`. То је Python функција приказана у листингу @listing-generate-k8s-manifests.

 
#figure(
	```python
def generate_k8s_manifests(model: SilveraModel, output_dir: Path) -> list[Path]:
		env = Environment(
				loader=FileSystemLoader(str(TEMPLATE_DIR)),
				undefined=StrictUndefined,
				trim_blocks=True,
				lstrip_blocks=True,
		)

		env.filters["kebab"] = _to_kebab

		written: list[Path] = []
		k8s_dir = output_dir / "infrastructure" / "kubernetes"
		k8s_dir.mkdir(parents=True, exist_ok=True)

		for svc in model.services:
				db_conn = svc.name.replace("Service", "") + "Db"
				tmpl = env.get_template("deployment.j2")
				content = tmpl.render(service=svc, db_connection_name=db_conn)
				target = k8s_dir / f"{_to_kebab(svc.name)}.generated.yaml"
				target.write_text(content, encoding="utf-8")
				print(f"[k8s] wrote {target}")
				written.append(target)

		written.append(_generate_ingress(model, k8s_dir))
		written.extend(_generate_config_manifests(model, k8s_dir))
		return written
	```
	, caption: [Функција за генерисање Kubernetes манифеста],
) <listing-generate-k8s-manifests>

 	
 	Функција generate_k8s_manifests се састоји од три фазе. Прва фаза је припрема, где се инстанцира Jinja2 Environment, друга фаза итерира кроз model.services и за сваки ServiceDef рендерује deployment.j2. Из модела користи само три вредности, а то су име, порт и изведени назив конекционог стринга, резултат ове фазе су четири манифест датотеке. На крају се праве заједнички манифести (yaml фајлови) за namespace, configMap, secret и ingress. Ови не иду кроз шаблон него су hardcoded Python стрингови, резултат ове фазе су 8 фајлова. Једини фајл који је потребно ручно написати је rabbitmq.yaml. 

У случају саме апликације за обраду поруџбине генерисане уз помоћ Silvera-е прво Terraform направи празан кластер. Kubernetes манифест фајлови га онда попуњавају изгенерисаним сервисима. Важно је да се напомене Terraform се покреће једном, док се манифест фајлови покрећу приликом сваког deploy-а. Укратко, Docker све спакује, Terraform прави место где ће радити, а  Kubernetes покреће. За микросервисну архитектури, где постоји велики број независних сервиса, Terraform и Kubernetes доста поједностављују управљање системом. Terraform омогућава поновљиво креирање истих окружења (development, testing, production), док је Kubernetes обезбеђује поуздано извршавање сервиса и динамичко прилагођавање оптерећењу. Управо из ових разлога Terraform и Kubernetes су циљне технологије које се користе за аутоматизацију самог процеса пребацивања апликације на облачне платформе, који се генеришу коришћењем Silvera-e. ЈСД може поједноставити сложеност ових технологија тако што корисник описује архитектуру система на вишем нивоу, док се конкретне Terraform и Kubernetes конфигурације генеришу аутоматски.
 
== Проширење Silvera-е подршком за пребацивање апликације и тестирање на Azure платформи

Azure платформа је једно од најраспрострањенијих окружења у облаку, које се користи за развој и извршавање микросервисних апликација. Нуди велики број сервиса који омогућавају скалабилност, високу доступност и једноставно управљање ресурсима. Да би интеграција Silvera-е са Azure платформом била могућа модел треба да се прошири да поред генерисања изворног кода, садржи и информације неопходне за аутоматско креирање конфигурација за пребацивање и извршавање апликације у облаку.


=== Мотивација за проширење
	
Потребе савременог софтверског инжењерства захтевају да апликација буде подржана у облаку, поготово ако је реч о микросервисној апликацији. Употребом Silvera-е могуће је да се моделује микросервисна архитектура и да се одради аутоматско генерисање изворног кода. Аутоматизовано постављање у облаку, тестирање и управљање животним циклусом апликације није подржано тим основним циклусом у Silvera-и, па се ту јавила потреба за проширењем. У пракси, процес пребацивања на облачно окружење често захтева да се ручно конфигурише инфраструктура, дефинишу сервиси, мрежна подешавања и параметари окружења. 

Главна мотивација је да се смањује количина ручног рада и да се упрости процес постављања микросервисне апликације. Из тих разлога јавила се потреба да се што већи део животног циклуса развоја софтвера подржи у оквиру Silvera-е. 
Проширењем Silvera-е тако да се генеришу неопходни артефакати за пребацивање на Azure платформу, у великој мери утичу на смањење количине ручног рада и поједностављује процес пребацивања микросервисне апликације. Омогућава аутоматизовано тестирање успешно пребачених сервиса, чиме се обезбеђује да генерисана апликација не само да буде исправно креирана, већ и функционално проверена након постављања.

=== Проширење метамодела и синтаксе

  	Проширење Silvera-е захтева да се дода одређена подршка код прављења самих модела. Та подршка је заправо коришћење метакласе `Plugin`. Користи се као врста декларације највишег нивоа, равноправна са већ постојећим декларацијама као што су `domain`, `service` и `event`. Начин додавања `Plugin` декларације приказан је у листингу @listing-plugin-declaration. Да би се користио `Plugin` додатак, потребно је дефинисати његов идентитет, односно назив, верзију и опис, као и циљну платформу (`target`) и врсту (`kind`).

 
#figure(
	```text
Declaration:
		DomainDecl | EnumDecl | EntityDecl | ...
	| PluginDecl                         // јединствена измена језгра
;

PluginDecl:
		'plugin' name=ID '{'
				('version' version=STRING)?
				('description' description=STRING)?
				('kind' kind=STRING)?
				('target' target=ID)?
				sections*=PluginSection
		'}'
;

PluginSection:
		SmokeTestsSection | LoadTestsSection | IntegrationTestsSection
	| PipelineSection | GenericSection;
	```
	, caption: [Дефинисање Plugin декларације у граматици],
) <listing-plugin-declaration>

У листингу @listing-azure-deployment-syntax приказан је семантички модел DeploymentTarget који омогућава пребацивање апликације на Azure. Ова класа се даље грана на ServiceDeployment; она носи CPU, memory, min/max-replicas, назив апликације и референцу на сервис из језгра. Логички сервис се тако претвара у ресурс који се може покренути. Следећа метакласа је ContainerAppsEnv, чијим додавањем метамодел добија две алтернативне платформе, док изведено својство uses_container_apps бира између њих. Ingress представља адресу сервиса и састоји се од порта и излазних адреса.


 
#figure(
  ```text
plugin AzureDeployment {
	container-apps-environment { ... }
	service-deployments {
		OrderService {
			cpu: 0.5
			liveness-probe: GET /health
		}
		PaymentService { ... }
	}
	ingress {
		routes {
			/api/v1/orders -> OrderService:8081
		}
	}
}
  ```
  , caption: [Синтаксни приказ Azure deployment модела],
) <listing-azure-deployment-syntax>


У листингу @listing-deployment-target-model приказано је како се овај модел представља у Python коду.

 
#figure(
	```python
@dataclass
class DeploymentTargetDef:
		container_apps_env: Optional[ContainerAppsEnvDef] = None
		service_deployments: list[ServiceDeploymentDef] = field(default_factory=list)
		ingress: Optional[IngressDef] = None
		monitoring: Optional[MonitoringDef] = None


@dataclass
class ServiceDeploymentDef:
		service: str
		cpu: float = 0.5
	```
	, caption: [Python модел метакласе за deployment],
) <listing-deployment-target-model>

 	Закључак је да проширење додаје језгру језика тачно једну метакласу Plugin, а сву платформску сложеност смешта иза њеног дискриминатора. Тиме основни Silvera модел остаје платформски независан, док пребацивање апликације и тестирање постају прворазредни, проверљиви делови модела уместо пратећих скрипти које се тихо разилазе са системом који описују.


=== Генерисање Azure конфигурације и пребацивање сервиса на Azure

Да би било омогућено да се Azure конфигурација изгенерише уз помоћ Silvera-е, потребно је да постоји .si фајл за почетак. У конкретном случају ове апликације назван је azure-deployment.si и представља Silvera модел, од кога ће настати све оно што је потребно за пребацивање апликације на Azure.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу azure-deployment.si  су дефинисане следеће ствари resource-group, container-registry, container-apps-environment, database, messaging, key-vault, service-deployments, ingress, monitoring. 

Како би пребацивање на Azure било могуће потребно је да постоји претходно креиран налог, који има одређене претплате које подржавају покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату Azure за студенте#footnote[https://azure.microsoft.com/en-us/free/students] и добила 100 долара бесплатног кредита који могу да користим. Када постоји креиран налог са активном претплатом потребно је да се одради команда az acr login, након ње docker compose build. На слици @slika-6-10-3-1 се види како то све изгледа након успешног пребацивања апликације на Azure-у. Све ово је смештено у оквиру order-tracking-rg ресурс групе.

 
#figure(image("../slike/slika-6.10.3-1.png", width: 90%), caption: [Ресурси order-tracking-rg групе]) <slika-6-10-3-1>
Поставка за Kubernetes сервисе је на слици @slika-6-10-3-2. 
#figure(image("../slike/slika-6.10.3-2.png", width: 90%), caption: [Kubernetes сервис]) <slika-6-10-3-2>


Укупан трошак ових сервиса за последња три месеца је приказан на слици @slika-6-10-3-3.
 
#figure(image("../slike/slika-6.10.3-3.png", width: 90%), caption: [Преглед трошкова за три месеца]) <slika-6-10-3-3>
Сви сервиси су смештени у оквиру Kubernetes сервиса order-tracking-aks, јер је то био једноставнији начин како би се покретање свих сервиса уклопило у претплату за Azure налог који користим. Преглед тога видљив је на слици @slika-6-10-3-4.

 
#figure(image("../slike/slika-6.10.3-4.png", width: 90%), caption: [Ресурси order-tracking-aks групе]) <slika-6-10-3-4>

=== Тестирање имплементираног решења на Azure платформи

Јако је битно да постоји одређен начин провере рада сервиса након што се апликација и њени сервиси пребаце на Azure. Апликација за обраду поруџбине, која је описана у овом мастер раду, део тестова је генерисан уз помоћу Silvera-е, док је један део писан ручно. Ручно писани су такозвани smoke тестови. Не постоји разлика између генерисаних тестова за Azure и  AWS,  ради се на исти начин. 

Сам приступ за генерисање тестова функционише другачије од већ описаних процеса за фајлове међу којима су services.si, events.si, communication.si, entities.si. У оквиру ових фајлова постоји додатак који генератор test_generator.py користи и уз помоћ Jinja шаблона штампа се као стварни Python код, помоћу кога се ствара прави Python фајл. Тестови који су изгенерисани и који су смештени у tests/generated/ су api_surface.py, ту имамо чисте податке, међу којима је листа свих рута и топологија догађаја. Изгенерисан тест test_auth_enforcement.py тестира јавне руте, тестира руте без токена и са неважећим токеном, псотоје и тест примери који покривају када се приступа са исправним токеном. Тест test_jwt_hardening.py испитује токене по сервису, тест test_messaging.py је задужен за испитивање порука. Што се самих догађаја тиче, покривени су тестовима тако што се проверава да ли постоји RabbitMQ exchange за сваки догађај који неко користи, проверава се да ли за сваки модел за који треба да постоје редови везани за exchange заправо постоје. Битно је да се види да ли сваки ред има бар једног активног consumer-а и да ли је durable (ако модел то тражи), да ли dead-letter ред постоји тамо где је декларисан и бави се пријављивањем „orphan" догађаја на информативном нивоу. Ручно писани тестови су smoke тестови и то је урађено из разлога што су то тестови којима се тестира имплементација, а не сам ЈСД модел.

Тестови се покрећу локално и постоје одређени кораци који треба да буду испуњени како би се покренули. Ако се приступа из терминала потребно је прво да се осигура аутентификација са Azure  налогом коришћењем команди:

#figure(```powershell
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" login --tenant tenantId
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" account set --subscription subscriptionId
& "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" aks get-credentials --resource-group order-tracking-rg --name order-tracking-aks
```, caption: [Аутентикација и преузимање Azure Kubernetes акредитива],) <listing-azure-auth-commands>

Треба покренути сервисе, препорука је да се покрену у оквиру пет одвојених терминала следеће команде:

#figure(```powershell
kubectl port-forward svc/order-service 8081:80 -n order-tracking
kubectl port-forward svc/payment-service 8082:80 -n order-tracking
kubectl port-forward svc/tracking-service 8083:80 -n order-tracking
kubectl port-forward svc/notification-service 8084:80 -n order-tracking
kubectl port-forward svc/rabbitmq 15672:15672 -n order-tracking
```, caption: [Прослеђивање портова Azure Kubernetes сервиса],) <listing-azure-port-forward>

Како би се утврдило да тестови приступају правим сервисима, потребно је прво проверити да локални сервиси нису покренути командом `docker ps`, која треба да врати празан резултат. Следећи корак је преузимање идентификатора процеса који се извршавају у Kubernetes-у, приказано у листингу @listing-process-connections.

 #figure(
	```powershell
PS C:\Users\Jovana\Desktop\order-tracking-system-master\order-tracking-system\order-tracking-system> Get-NetTCPConnection -LocalPort 8081,8082,8083,8084 -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess

LocalPort OwningProcess
--------- -------------
		 8084         15428
		 8083         32940
		 8082         36252
		 8081         28232
	```
	, caption: [Приказ идентификатора процеса за прослеђене портове],
) <listing-process-connections>

Колона `OwningProcess` представља идентификатор процеса. Њихови детаљи приказани су у листингу @listing-kubectl-processes.

#figure(
	```text
PS C:\Users\Jovana\Desktop\order-tracking-system-master\order-tracking-system\order-tracking-system> Get-Process -Id 15428, 32940, 36252, 28232

Handles  NPM(K)  PM(K)  WS(K)  CPU(s)    Id ProcessName
-------  ------  -----  -----  ------    -- -----------
		209      19  60240  37680    0.23 15428 kubectl
		209      19  60204  36880    0.44 32940 kubectl
		205      19  60236  37996    0.22 36252 kubectl
		208      19  60396  37372    0.19 28232 kubectl
	```
	, caption: [Детаљи процеса за прослеђене Kubernetes сервисе],
) <listing-kubectl-processes>

Када имамо све проверено на овај начин, осигурано је да покренути тестови се извршавају на Azure платформи. Покретање тестова се врши тако што се прво навигира до директоријума где се налазе тестови, а затим покрену следећим командама

#figure(```powershell
python tests\generated\test_auth_enforcement.py
python tests\generated\test_jwt_hardening.py
python tests\generated\test_messaging.py
python tests\smoke_test.py
```, caption: [Покретање тестова на Azure платформи],) <listing-azure-test-commands>


Резултати покретања `test_auth_enforcement.py` тестова:
#figure(```text
Section 1 — Public endpoints
All health and readiness endpoints passed for all 4 services.
Section 2 — Missing token
All protected endpoints correctly returned 401 without a JWT.
Section 3 — Invalid token
All protected endpoints correctly rejected tokens signed with an invalid key.
Section 4 — Valid token control
Valid JWTs were accepted by all 4 services.
Results: 48 passed | 0 failed | 0 skipped
```, caption: [Резултати теста test_auth_enforcement.py на Azure платформи],) <listing-azure-auth-results>

Резултати покретања `test_jwt_hardening.py`:
#figure(```text
JWT hardening
Section 1 — Invalid tokens
All 8 invalid JWT cases were correctly rejected by all 4 services.
Section 2 — Token validation
Expired, wrong issuer/audience, wrong key, tampered, malformed and invalid authorization schemes were rejected.
Section 3 — Valid token control
Correctly signed JWTs were accepted by all 4 services.
Results: 36 passed | 0 failed | 0 skipped

```, caption: [Резултати теста test_jwt_hardening.py на Azure платформи],) <listing-azure-jwt-results>

Резултати покретања `test_messaging.py` тестова:

#figure(```text
Messaging Topology
Section 1 — Broker connectivity
RabbitMQ API reachable and broker version verified.
Section 2 — Exchanges
All 5 consumed event exchanges were correctly declared.
Section 3 — Event routing
All events were correctly routed to the modeled services.
Section 4 — Receive endpoints
All 8 receive endpoints were correctly configured.
Section 5 — Dead-letter queues
All 8 dead-letter queues were correctly configured.
Section 6 — Orphan events
PaymentRefundedEvent has no subscribers and was skipped.
Results: 27 passed | 0 failed | 1 skipped
```, caption: [Резултати теста test_messaging.py на Azure платформи],) <listing-azure-messaging-results>

Резултати smoke тестова су представљени на овај начин: 

#figure(
	```text
Order Tracking System — Integration Test Suite
Section 1 — Health checks
All health and readiness endpoints passed for all 4 services.
Section 2 — Auth enforcement
All protected endpoints correctly rejected requests without JWT.
Section 3 — API validation
Authenticated reads, 404 handling and pagination were verified.
Section 4 — Messaging infrastructure
RabbitMQ exchanges, queues and receive endpoints were correctly configured with no failed or orphaned messages.
Section 5 — Stub behaviour
PaymentService stub endpoint behaved as expected.
Section 6 — End-to-end event flow
Order creation and status changes were successfully propagated and persisted across services.
Section 7 — Full API surface
GET, POST, PUT and DELETE operations were successfully exercised across all services.
Section 8 — Data integrity
Order fields, business rules, cancellation, tracking consistency and pagination were verified.
Section 9 — JWT hardening
Invalid JWTs were rejected and correctly signed tokens were accepted.
Results: 110 passed | 0 failed | 0 skipped
All checks passed.
```, caption: [Резултати smoke тестова на Azure платформи],) <listing-azure-smoke-results>

 

== Проширење Silvera-е подршком за пребацивање и тестирање на AWS платформи

Amazon Web Services (AWS) је једно јако популарно окружење у облаку које се користи за развој и извршавање микросервисних апликација. Развила га је компанија Amazon. AWS пружа велики број сервиса које покривају готово све области развоја и одржавања апликација, укључујући рачунарске ресурсе, као што су виртуелне машине, контејнере и serverless функције, затим складиштење података, базе података, мрежне сервисе, безбедност и управљање приступом, вештачку интелигенцију и аналитику. Једна од највећих предности AWS-а је скалабилност, односно могућност повећања или смањења ресурса у складу са тренутним потребама апликације. Поред тога, AWS користи модел плаћања по потрошњи (pay-as-you-go), што значи да корисници плаћају само оне ресурсе које су заиста користили. 


=== Проширење метамодела и синтаксе

Идентична прича која је постојала као и за Azure, потребно је да се прошири Silvera-е и то је учињено на начин да се да додатна подршка код прављења самих модела. Та подршка је заправо коришћење метакласе Plugin. Као и раније што је поменуто, да би се користио Plugin додатак потребно је за почетак да се дефинише идентитет. Дефинисање идентитета је заправо одређивање назива, верзије и описа. Након тога потребно је написати циљну платформу (target) која је у овом случају AWS. Затим је потребно да се одреди и врста (kind), да ли је у питању deployment или testing. Врста се у овом случају назива још и дискриминатором, јер од ње зависи који ће се ток даље преузети. У конкретној апликацији када се изабере да је kind = deployment, тада се одабере ток који креира метакласе које омогућавају  пребацивање апликације на AWS. 

Семантички модел који омогућава пребацивање апликације на AWS је DeploymentTarget.

#figure(
  raw("name = 'AwsEc2Deployment'\\ntarget = 'aws-ec2'\\nregion = 'us-east-1'\\napp_name = 'order-tracking'\\ninstance_type = 't3.micro'\\ndisk_gb = 30\\nswap_gb = 6\\nallowed_ssh_cidr = '0.0.0.0/0'\\nallowed_app_cidr = '0.0.0.0/0'\\nmessaging_type = 'rabbitmq-container'\\nmessaging_mgmt_port = 15672", lang: "text"),
  caption: [Дефинисање AWS deployment модела],
) <listing-6-11-1-1>


=== Генерисање AWS конфигурације и пребацивање сервиса на AWS

Silvera модел који је задужен за генерисање AWS конфигурација је aws-ec2-deployment.si.  Процес функционише тако што се из овог фајла генерише све што је потребно за Terraform. У фајлу aws-ec2-deployment.si  су дефинисане ствари које су потребне да буду подржане за креирање Terraform скрипти. Има следеће информације version, description, target, provider, compute, messaging. 

Како би пребацивање на AWS било могуће потребно је да постоји претходно креиран налог који има одређене претплате које би омогућиле покретање ових сервиса. За потребе овог мастер рада, након направљеног налога, активирала сам претплату AWS Free Tier#footnote[https://aws.amazon.com/free/] и имала сам могућност да добијем првих 100 долара бесплатног кредита који могу да користим наредна три месеца, уз одређена ограничења. AWS сервиси су поприлично скупи, па је било потребно да се обрати пажња да се изаберу неке јефтиније верзије, како се не би одмах потрошио читав кредит. Након што је све изгенерисано, потребно је да се покрену ове команде, да се дода кључ и тајна са AWS налога, на тај начин је омогућен приступ, након тога aws configure и након тога terraform apply.

 
#figure(image("../slike/slika-6.11.2-1.png", width: 90%), caption: [Приказ EC2 инстанци]) <slika-6-11-2-1>

 
#figure(image("../slike/slika-6.11.2-2.png", width: 90%), caption: [Детаљан order-tracking-sg приказ ресурса]) <slika-6-11-2-2>

 
=== Тестирање имплементираног решења на AWS платформи

 	Као што је већ споменуто генерисање тестова за Azure и AWS се одвија на исти начин, јер су фајлови services.si, events.si, communication.si, entities.si где се налазе Silvera модели проширени како би подржали генерисање тестова. Овде су такође smoke тестови ручно направљени из истих разлога, јер се њима тестира сама имплементација, а не сами ЈСД модели. Детаљније о самим тестовима и њиховом дефинисању у оквиру апликације налази се у поглављу  6.10.4 Тестирање имплементираног решења на Azure платформи. Пошто су исти тестови, како би тестирали њихово понашање на различитим платформама, битан је начин на који се све ово покреће. Међу првим корацима је то да се преко терминала улогује на одговарајући AWS налог, где су постављени сервиси. Потребно је покренути команде, чији излаз би требао да буде running 3.84.174.154

#figure(```powershell
aws ec2 describe-instances --instance-ids i-076084e187740f8e0 --region us-east-1 ` --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" --output text
```, caption: [Провера стања AWS EC2 инстанце],) <listing-aws-instance-command>


Проверити да ли се овде враћа као статус health, за следеће команде

#figure(```powershell
curl http://3.84.174.154:8081/health
curl http://3.84.174.154:8082/health
curl http://3.84.174.154:8083/health
curl http://3.84.174.154:8084/health
```, caption: [Провера здравственог стања AWS сервиса],) <listing-aws-health-commands>

Команде за покретање тестова су:

#figure(```powershell
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
       --mode aws `
       --order-url http://3.84.174.154:8081 `
       --payment-url http://3.84.174.154:8082 `
       --tracking-url http://3.84.174.154:8083 `
        --notification-url http://3.84.174.154:8084 `
 --rabbitmq-url http://3.84.174.154:15672
```, caption: [Покретање тестова на AWS платформи],) <listing-aws-test-commands>

Резултати када се покрену тестови из test_auth_enforcement.py

#figure(```text
Section 1 — Public endpoints
All health and readiness endpoints passed for all 4 services.
Section 2 — Missing token
All 18 protected endpoints correctly returned 401 without a JWT.
Section 3 — Invalid token
All protected endpoints correctly rejected JWTs signed with an invalid key.
Section 4 — Valid token control
Valid JWTs were accepted by all 4 services.
Results: 48 passed | 0 failed | 0 skipped
```, caption: [Резултати теста test_auth_enforcement.py на AWS платформи],) <listing-aws-auth-results>
Резултати када се покрену тестови из test_messaging.py
                                         
#figure(```text
Section 1 — Broker connectivity
RabbitMQ management API was reachable and broker version was verified.
Section 2 — Exchanges
All 5 consumed event exchanges were correctly declared.
Section 3 — Event routing
All events were correctly routed to the modeled services.
Section 4 — Receive endpoints
All 8 receive endpoints were correctly configured.
Section 5 — Dead-letter queues
All 8 dead-letter queues were correctly configured.
Section 6 — Orphan events
PaymentRefundedEvent has no subscribers and was skipped.
Results: 27 passed | 0 failed | 1 skipped
```, caption: [Резултати теста test_messaging.py на AWS платформи],) <listing-aws-messaging-results>
Резултати када се покрену тестови из jwt_hardening.py

#figure(```text
Section 1 — Bad tokens
All 8 invalid JWT cases were correctly rejected by all 4 services.
Section 2 — Token validation
Expired, wrong issuer/audience, wrong key, tampered, malformed and invalid authorization schemes were rejected.
Section 3 — Valid token control
Correctly signed JWTs were accepted by all 4 services.
Results: 36 passed | 0 failed | 0 skipped
```, caption: [Резултати теста jwt_hardening.py на AWS платформи],) <listing-aws-jwt-results>
Резултати када се покрену smoke тестови
 
#figure(```text
Section 1 — Health checks
All health and readiness endpoints passed for all 4 services.
Section 2 — Auth enforcement
All protected endpoints correctly rejected requests without JWT.
Section 3 — API validation
Authenticated reads, 404 handling and pagination were verified.
Section 4 — Messaging infrastructure
RabbitMQ exchanges, queues and receive endpoints were correctly configured with no orphaned or failed messages.
Section 5 — Stub behaviour
PaymentService stub endpoints responded as expected.
Section 6 — End-to-end event flow
Order creation and status changes were successfully propagated and persisted across services.
Section 7 — Full API surface
GET, POST, PUT and DELETE operations were successfully exercised across all services.
Section 8 — Data integrity
Order fields, business rules, cancellation, tracking consistency and pagination were verified.
Section 9 — JWT hardening
Invalid JWTs were rejected, while a correctly signed token was accepted.
Results: 110 passed | 0 failed | 0 skipped
All checks passed.
```, caption: [Резултати smoke тестова на AWS платформи],) <listing-aws-smoke-results>
Тестови који се овде извршавају локално комуницирају са сервисима који су доступни на AWS EC2 инстанцама. Циљ је да покрију што већу функционалност и међусобну комуникацију сервиса у окружењу које је блиско реалном продукционом окружењу. Овим приступом се на једноставнији начин врши провера интеграције микросервисне апликације и представља једну од могућности за њено извршавање и тестирање у AWS облаку.
