/*
Aanvraag: 26-01697 
Schrijver: [analist]
Datum: 27-7-2026
Dit keer ook NST (morf 8500) + enkele aanvullende variabelen


*/


/**************************************************************************/
/* Aanvraag: 25-01377                                                     */
/* Schrijver: [analist]                                                  */
/*                                                                        */
/* Aanvrager: [aanvrager]                                                  */
/* Titel: [titel studie naar invasief lobulair carcinoom]           */
/*                                                                        */
/* Datum: 04-03-2026                                                      */
/* Laatste wijziging: 05-03-2026                                          */
/*                                                                        */
/* Selectie: 2005-2019, borst,invasief lobulairca., stadium I-III, 18+    */
/*                                                                        */
/* Extra informatie:                                                      */
/*                                                                        */
/**************************************************************************/

/* Vul het jaartal en volgnummer van de gegevensaanvraag in */
%let jr  = 26;    * jaartal van de aanvraag (2 cijfers);
%let nr  = 01697; * nummer van de aanvraag (5 cijfers);
%let dir = <leveringsmap>\20&jr\&jr.-&nr;
options nodlcreatedir;
libname dir "&dir";
options dlcreatedir noquotelenmax;
libname lever "&dir\levering";


*** STANDAARDSELECTIE ***;
sasfile krn.kern load; 
data tum;
   set krn.kern ;
   if tumsoort in (501300); 	    
   if tum_incl in (1);	* Tumor binnen inclusiecriteria NKR;
   if nl_incl in (1);	* Woonachtig in Nederland ten tijde van diagnose;
   if ond_gebruik = 1; * indien gebruik voor wetenschappelijk onderzoek;
   if 2005 <= incjr <= 2019; 
   if epis in ('DIA');	* wannneer ook toevalsbevinding bij obductie nodig ook op OBD selecteren (over het algemeen alleen gebruikt bij incidentiecijfers);
   if gesl in (1,2);	* geslacht=3 (hermafrodiet) wordt niet geleverd bij recordniveau ivm te kleine aantallen en mogelijk herleidbaarheid;
   if leeft >= 18;
   if regstat = 0;
   %kerntherapie; *toevoegen kernbestand therapie;
   %kernborst; *toevoegen tumorspecifiek kernbestand;
run;
sasfile krn.kern close; 

* Eerste impressie van de data;
proc freq data=tum;
	tables gesl leeft tumsoort incjr topo_sublok morf later gedrag diffgrad diag_basis tum_incl nl_incl ond_gebruik epis iacr reg_afgerond regstat stadium figo ceod ann_arbor;
	format gesl geslcde. tumsoort tumsoort3ncde. topo_sublok $topo_sublokcde. morf morfcde. later $latercde. gedrag gedragcde. diffgrad $diffgradcde. diag_basis diag_basiscde. regstat regstatcde.;
run;

/********************/
/* Verdere selectie */
/********************/

* hormoonreceptor-positief (minimaal ER+ of PR+)& her2-negatief;
proc freq; tables er_stat*pr_stat*her2_stat/list missing; where morf = 8520; run; * 1 positief voor er/pr, voor her2 0 en 1 ;

data tum1; set tum;  
	if morf in (8520,8500);
	if er_stat=1 or pr_stat=1; 
	if her2_stat in (0,1); 
run; 

* selectie op stadium I-III; 
proc freq data=tum1; tables stadium; run; 

data tum2; set tum1; 
	if substr(stadium,1,1) in ("1", "2", "3"); 
run; 

* selectie op geen eerder maligniteit < 5 jaar, uitgezonderd insitu en BCC); 
%anderemaligniteit(tum2, format=W, periode=E, maanden=0-60, gedrag=3-9, tum_incl=1, regstat=0 1 5);

proc freq; tables mal; run; 

data tum3; set tum2;
	if mal = 0; 
run;  

/**************/
/* Variabelen */
/**************/

* leeftijd om zetten in categorien van 5 jaar 16-20;

%leeft_cat(tum3, leeft_cat=5, leeft_min=24, leeft_plus=85);  * aanmaken van leeftijdscategorieï¿½n, kan ook met custom leeftijdscategorieï¿½n, zie macro toelichting. 5-jaars met 85+ is conform NKR-cijfers;

proc freq; tables leeft*leeft_cat/list missing; run; 

/* andere maligniteiten langer dan 5 jaar geleden */
* De eerdere opgehaalde eerdere maligniteiten verwijderen; 
data tum5; set tum3; 
	drop mal: ; 
run; 

*opnieuw eerdere maligniteiten ophalen maar nu langer dan 5 jaar geleden ben er vanuit gegaan zelfde inclusie als de exclusie; 
%anderemaligniteit(tum5, format=L, periode=E, maanden=60-9999, gedrag=3-9, tum_incl=1, regstat=0 1 5);

data tum5_andermal2; set tum5_andermal; 
	rename mal_eid = eid; 
run; 

%kernsystemisch(tum5_andermal2, grp=0, extravars=1); * Toevoegen systemische therapie;

proc print data=tum5_andermal2 (obs=100); run; 

*alleen systcode houden voor eerdere borstmaligniteiten; 
data tum5_andermal3; set tum5_andermal2; 
	array syst_code(8) syst_code1-syst_code8; 
	do i = 1 to 8 ; 
	if mal_tumsoort ne 501300 then syst_code(i) = ""; 
	end;
	drop syst_start_int: syst_stop_int: syst_kuren: syst_chemort: 
		 syst_gid: syst_volgnum: syst_regcode: syst_startdat: syst_stopdat: 
		 syst_zkh: syst_prepost: i;
	rename eid = mal_eid; 
run; 

%rename(tum5_andermal3, varlist=mal_int: mal_tumsoort:, droppre=4);

proc contents data=tum5_andermal3; run;
 
*omzetten in wide om terug te zetten aan de primaire tumor; 
%transpose(tum5_andermal3, format=W, byvar=prim_eid mal_incdat mal_eid, idvar=prim_eid, copyvar=rn, varlist=int tumsoort, newlist=, varpre=mal, varsuf=, labbron=L, labpre=Eerdere maligniteit, labsuf=,volgnum=4, out=mal_out1);
%transpose(tum5_andermal3, format=W, byvar=prim_eid mal_incdat mal_eid, idvar=prim_eid, copyvar=rn, varlist=syst_code:, newlist=, varpre=mal, varsuf=, labbron=L, labpre=Eerdere borstmaligniteit, labsuf=,volgnum=2, out=mal_out2);


* terug koppelen aan selectie bestand; 
proc sql; 
	create table tum6 as
	select *
	from tum5 as a 
	left join mal_out1 as b on a.eid=b.prim_eid
	left join mal_out2 as c on a.eid=c.prim_eid
;
quit; 

proc print data=tum6 (obs=100); run; 


/* systemische therapie toevoegen in groepen */
%kernsystemisch(tum6, grp=1, extravars=1); * Toevoegen systemische therapie;


%uitslagdetail(tum6, 50D15-8170, oksel_echo_uitslag, stat=1, dat=1, format=1);

proc freq data=tum6;
table incjr*oksel_echo_uitslag_stat1*oksel_echo_uitslag_stat2*oksel_echo_uitslag_stat3  oksel_echo_uitslag1*oksel_echo_uitslag2*oksel_echo_uitslag3 / list missing;
run;

data tum7;
	set tum6;
if incjr < 2014 then do;
		oksel_echo_uitslag_stat1 = "";
		oksel_echo_uitslag_stat2 = "";
		oksel_echo_uitslag_stat3 = "";
		oksel_echo_uitslag1 = .;
		oksel_echo_uitslag2 = .;
		oksel_echo_uitslag3 = .;
		oksel_echo_uitslag_dat1 = .;
		oksel_echo_uitslag_dat2 = .;	
		oksel_echo_uitslag_dat3 = .;
end;
if oksel_echo_uitslag_stat1 = "JA" then oksel_echo1 = 1 ;
if oksel_echo_uitslag_stat2 = "JA" then oksel_echo2 = 1;
if oksel_echo_uitslag_stat3 = "JA" then oksel_echo3 = 1; 
if oksel_echo_uitslag_stat1 = "NEE" then oksel_echo1 = 0;
if oksel_echo_uitslag_stat1 = "JA" then oksel_echo_int1 = oksel_echo_uitslag_dat1 - incdat;
if oksel_echo_uitslag_stat2 = "JA" then oksel_echo_int2 = oksel_echo_uitslag_dat2 - incdat;
if oksel_echo_uitslag_stat3 = "JA" then oksel_echo_int3 = oksel_echo_uitslag_dat3 - incdat;
label 
oksel_echo1 = "Echogeleide punctie uitgevoerd 1" 
oksel_echo2 = "Echogeleide punctie uitgevoerd 2" 
oksel_echo3 = "Echogeleide punctie uitgevoerd 3" 
oksel_echo_int1 = "Interval incidentiedatum en datum van echogeleide punctie 1" 
oksel_echo_int2 = "Interval incidentiedatum en datum van echogeleide punctie 2" 
oksel_echo_int3 = "Interval incidentiedatum en datum van echogeleide punctie 3" ;	
if oksel_echo_uitslag_stat1 = "NEE" and oksel_echo_uitslag_stat2 = "JA" then do;
	oksel_echo_uitslag1 = oksel_echo_uitslag2;
	oksel_echo_uitslag2 = .;
	oksel_echo1 = 1;
	oksel_echo2 = .;
	oksel_echo_int1 = oksel_echo_int2;
	oksel_echo_int2 = .;
end;
run;


proc freq data=tum7;
table incjr*oksel_echo1*oksel_echo2*oksel_echo3  oksel_echo_uitslag1*oksel_echo_uitslag2*oksel_echo_uitslag3 / list missing;
run;


*** LEVERINGSBESTAND op recordniveau ***;
%let jroud  = 25;    * jaartal van de aanvraag (2 cijfers);
%let nroud  = 01377; * nummer van de aanvraag (5 cijfers);
* rn en eid uniek maken;
data key (drop = key_seed);
	set tum7;
	key_seed = input(cats("&jroud",put(&nroud,z5.0)),8.);
	key_nkr  = input(reverse(put(rn+key_seed,z9.)),9.);
	key_zid  = input(reverse(put(zid+key_seed,z8.)),8.);
	key_eid  = input(reverse(put(eid+key_seed,z8.)),8.);
	label 
	key_nkr = 'Keynummer patiï¿½nt' 
	key_zid = 'Keynummer tumor' 
	key_eid = 'Keynummer tumor' 
; /* Bij leveren key_zid als Keynummer tumor wordt het label van key_eid "Keynummer episode" */
run;

%checkleeg(key, incllist=:syst_code:, drop=1, out=key);

* Zet hier de variabelen die je wilt leveren, in de gewenste volgorde. Wil je alle variabelen uit je bestand leveren gebruik dan keyword _all_ ipv een variabelen lijst;
%let variabelen = 
  key_nkr key_eid 
  gesl incjr leeft_cat mal: meno_stat vit_stat_int vit_stat
  topo_sublok later morf diffgrad diag_basis ct cn cm pt pn pm cstadium pstadium stadium ond_lymf pos_lymf
  tum_afm multifoc er_stat er_waarde pr_stat pr_waarde her2_stat her2_tech mammaprint_uitslag oncotype_uitslag
  chir chir_type: chir_int: uitgebr_chir_type uitgebr_chir_int
  inv_rad_laatste dcis_rad_laatste residu okd rt chemo chemo_code: chemo_start_int: chemo_stop_int: 
  horm horm_code: horm_start_int: horm_stop_int: target target_code: target_start_int: target_stop_int:
  mri mri_int mari mari_int mari_uitslag swk swk_int swk_uitslag oksel_echo1-oksel_echo3 oksel_echo_uitslag1-oksel_echo_uitslag3 oksel_echo_int1-oksel_echo_int3
;        

* Bestand aanmaken met alleen de te leveren variabelen in de juiste volgorde;
%varvolgorde(key, &variabelen, out=levering, keep=1);

* Exporteren data naar csv-bestand voor aanvrager;
options nosource;
proc export data=levering outfile = "&dir\&jr.-&nr..csv" dbms=csv replace;
   delimiter='3b'x ; 
run;     
options source;

* Ritssluiting bewaren met alle episodes die in levering zitten;
data dir.key_&jr&nr (keep = key_nkr key_zid key_eid rn zid eid epis dwh_release dwh_exportdat);
	retain key_nkr key_zid key_eid rn zid eid epis dwh_release dwh_exportdat;
	set key;
run;



*** AANMAKEN DATA DICTIONARY ***;

/* Opgeven gebruikte tumorspecifieke kernbestand(en) voor de selectie.  
   - Algemene kernbestanden (Kern, Systemisch, Therapie, Comorbiditeit, Metastase) worden altijd meegenomen -> niet opgeven.  
   - Geen kernbestand nodig? -> macrovariabele leeglaten maar wï¿½l aanmaken. */
%let kernbestand = borst ;

/* Automatisch formats aanmaken via een TUMORSPECIFIEK kernbestand. Heb je geen kernbestand dan deze stap uitzetten */
%formatdetail(&kernbestand, sort=D, multilabel=0);


/* Format aanmaken voor er_waarde en pr_waarde */
proc format;
	value tum_afm 
		999 = 'Onbekend'
		other = 'Aantal millimeter';
	value horm_waarde (multilabel)
		0 = 'Niet bepaald [__/__/____-31/12/2010]'
		1 = 'Positief (>10% positieve tumorcellen) [__/__/____-31/12/2010]'
		2 = 'Negatief (<=10% positieve tumorcellen) [__/__/____-31/12/2010]'
		3 = 'Uitslag niet te beoordelen of onbekend [__/__/____-31/12/2010]'
		0 = 'Negatief (0-9%, of zonder vermelding van %) [01/01/2011-__/__/____]'
		1 = 'Positief (uitslag positief zonder vermelding %) [01/01/2011-31/12/2017]'
		10 = '10-19% [01/01/2011-31/12/2017]'
		20 = '20-29% [01/01/2011-31/12/2017]'
		30 = '30-39% [01/01/2011-31/12/2017]'
		40 = '40-49% [01/01/2011-31/12/2017]'
		50 = '50-59% [01/01/2011-31/12/2017]'
		60 = '60-69% [01/01/2011-31/12/2017]'
		70 = '70-79% [01/01/2011-31/12/2017]'
		80 = '80-89% [01/01/2011-31/12/2017]'
		90 = '90-100% [01/01/2011-31/12/2017]'
		99 = 'Uitslag niet te beoordelen of onbekend [01/01/2011-31/12/2017]'
		111 = 'Positief (zonder vermelding van %) [01/01/2018-__/__/____]'
		999 = 'Uitslag niet te beoordelen, onbekend of zwak positief [01/01/2018-__/__/____]'
		other  = 'Waarde in % [01/01/2018-__/__/____]';
run;

/* Automatisch formats koppelen. Let op: detailcode formats moeten hierboven eerst zijn aangemaakt via %formatdetail. */
%formatbestand(levering, out=datadict1, kernbest=&kernbestand, format=txt);

/* Handmatig overige formats koppelen.  
   - Je kan hiermee formats uit %formatbestand overrulen of verwijderen.  
   - Verwijderen? -> alleen variabelenaam opgeven (zonder format).  
   - Niet nodig? -> zet de format-regel uit, zodat dataset datadict2 wel wordt aangemaakt.  
   - Vergelijkbare variabelen krijgen hetzelfde format, je geeft iedere formatnaam dus maar 1X op. */
data datadict2;
	set datadict1;
	format tum_afm tum_afm. er_waarde pr_waarde horm_waarde. oksel_echo1-oksel_echo3 janeetxt.; 
run;


/* Algemeen/vraagstelling: alles in 1 regel code -> er wordt 1 record aangemaakt.  
   - Lange tekst? -> enter mag, maar nieuwe regel starten met spatie (anders plakt tekst in Excel aan elkaar). */   
data algemeen_vraagst;
	length algemeen_vraagst $30000; 
	algemeen_vraagst = "Update van dataset 25-01377, met ook morfologiecode 8500 als controlegroepï¿½";
run;

/* Selectiecriteria: maak altijd de volledige 10 records aan.  
   - Niet van toepassing? -> "xxx" laten staan of leegmaken (in Excel verschijnt "-").  
   - Lange tekst? -> enter mag, maar nieuwe regel starten met spatie (anders plakt tekst in Excel aan elkaar). */
data selectiecriteria;
	length selcrit $5000;
	/* "Tumor: lokalisatie(s)        */ selcrit = "Borst"; output;
	/* "Tumor: morfologie(en)        */ selcrit = "8520 Lobulair carcinoom + 8500 Ductaal carcinoom, NNO"; output;
	/* "Tumor: stadium/stadia        */ selcrit = "(gecombineerd) stadium I-III"; output;
	/* "Tumor: gedrag                */ selcrit = "Invasief"; output;
	/* "Patiï¿½nt: geslacht            */ selcrit = "Beide"; output;
	/* "Patiï¿½nt: leeftijd (indeling) */ selcrit = "18+"; output;
	/* "Diagnosejaren/-periode       */ selcrit = "2005-2019"; output;
	/* "Niveau van de selectie       */ selcrit = "Landelijk"; output;   /* Landelijk, Regio, Ziekenhuis, Cohort, etc. Bij niveau ziekenhuis ook vermelden welke ziekenhuizen je levert */
	/* "Behandeling(en)              */ selcrit = "xxx"; output;
	/* "Overige criteria             */ selcrit = "Hormoonreceptor-positief (minimaal ER+ of PR+), Her2-negatief, geen eerdere maligniteit < 5 jaar voor diagnose (uitgezonderd insitu en BCC) "; output;
run;

/* Handmatig toelichting toevoegen per variabele. Dit overschrijft evt. toelichting uit het DWH.  
   - Geldt de toelichting voor een reeks (bijv. chir_tech1, chir_tech2)? -> 1x opgeven zonder nummer (chir_tech).  
   - Prefixen 'mal', 'fup' en 'epis' worden automatisch meegenomen, dus hoef je niet op te geven.  
   - Zelfde toelichting voor verschillende variabelen (bijv. chir_rad en expl_chir_rad)? -> beide apart opgeven.  
   - Lange tekst? -> enter mag, maar begin nieuwe regel met spatie (anders plakt tekst in Excel aan elkaar).  
   - Toelichting verwijderen? -> lege waarde opgeven (toelichting = "", geen "xxx"). */
data toelichting_vars;
	length variabelenaam $32 toelichting $5000;
	variabelenaam = "xxx"; toelichting = "xxx"; output;
	variabelenaam = "xxx"; toelichting = "xxx"; output;
	variabelenaam = "xxx"; toelichting = "xxx"; output;
run;

/* Aanmaken van Data Dictionary Excel-bestand. Taal=2 geeft een Engelstalige Data Dictionary. 
   In excllist= kan je variabelen opgeven waarvoor de codelijst niet gefilterd moet worden op voorkomende waarden in het bestand */
%datadictionary(datadict2, bestand=&jr.-&nr..csv, outdir=&dir, outfile=&jr.-&nr._Data_Dictionary, kernbest=&kernbestand, taal=1, filter=1, excllist=);
