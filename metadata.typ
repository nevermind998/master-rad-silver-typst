#let format_strane = "iso-b5"         // могуће вредности: iso-b5, a4
#let naslov = [ Генератор кода за _AWS_ и _Azure_ из _Silvera_ језика специфичног за домен описа
    система базираних на микросервисима ]
#let autor = "Јована Арсовић"

// На енглеском
#let naslov_eng = "A source code generator for AWS and Azure based on the Silvera domain-specific language for microservice-based systems"
#let autor_eng = "Jovana Arsović"

#let indeks = "R234/22"

// Име и презиме ментора
#let mentor = "Игор Дејановић"
// Звање: редовни професор, ванредни професор, доцент
#let mentor_zvanje = "редовни професор"

// Скинути коментаре са одговарајућих линија
#let studijski_program = "Софтверско инжењерство и информационе технологије"
//#let studijski_program = "Софтверско инжењерство"
#let stepen = "Мастер академске студије"
//#let stepen = "Основне академске студије"

#let godina = [#datetime.today().year()]

#let kljucne_reci = "језик специфичан за домен, микросервисна архитектура, генерисање кода, Silvera, AWS, Azure"
#let apstrakt = [
     Рад приказује примену језика специфичног за домен Silvera за аутоматско
     генерисање микросервисне апликације за обраду поруџбина, као и њено
     пребацивање на облачне платформе AWS и Azure. Приказани приступ се пореди
     са постојећим решењима за опис домена, архитектуре и API интерфејса.
]

// На енглеском
#let kljucne_reci_eng = "domain-specific language, microservice architecture, code generation, Silvera, AWS, Azure"
#let apstrakt_eng = [
     This thesis presents the use of the Silvera domain-specific language for
     automatic generation of a microservice application for order processing,
     including deployment to AWS and Azure cloud platforms. The approach is
     compared with existing solutions for domain, architecture, and API description.
]

// TODO: Текст задатка добијате од ментора. Заменити доле #lorem(100) са текстом задатка.
#let zadatak = [
     Проучити језике специфичне за домен и њихову примену у развоју
     микросервисних система. Анализирати језик Silvera, реализовати генерисање
     апликације за обраду поруџбина и испитати пребацивање генерисаних сервиса
     на AWS и Azure платформе. Упоредити добијени приступ са релевантним
     постојећим решењима.
]

// TODO: Датум одбране и чланове комисије добијате од ментора
#let datum_odbrane = "25.09.2026"
#let komisija_predsednik = "Гордана Милосављевић"
#let komisija_predsednik_zvanje = "редовни професор"
#let komisija_clan = "Јована Видаковић"
#let komisija_clan_zvanje = "ванредни професор"

// На енглеском уписати чланове на латиници
#let komisija_predsednik_eng = "Gordana Milosavljević"
#let komisija_clan_eng = "Jovana Vidaković"
#let mentor_eng = "Igor Dejanović"


// Ово даље углавном не треба мењати.

#let zvanje_eng = (
     "редовни професор": "full professor",
     "ванредни професор": "assoc. professor",
     "доцент": "asist. professor",
)
#let komisija_predsednik_zvanje_eng = zvanje_eng.at(komisija_predsednik_zvanje)
#let komisija_clan_zvanje_eng = zvanje_eng.at(komisija_clan_zvanje)
#let mentor_zvanje_eng = zvanje_eng.at(mentor_zvanje)


#let vrsta_rada = if stepen == "Мастер академске студије" {
    "Дипломски - мастер рад"
} else {
    "Дипломски - бечелор рад"
}

#let oblast = "Електротехничко и рачунарско инжењерство"
#let oblast_eng = "Electrical and Computer Engineering"
#let disciplina = "Примењене рачунарске науке и информатика"
#let disciplina_eng = "Applied computer science and informatics"

#import "funkcije.typ": *
// Поглавља/страна/цитата/табела/слика/графика/прилога
#let fizicki_opis = physical()
