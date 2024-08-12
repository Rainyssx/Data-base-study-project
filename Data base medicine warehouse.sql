--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

-- Started on 2024-05-13 20:48:47

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 24606)
-- Name: active_ingredient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_ingredient (
    trade_name character varying(60) NOT NULL,
    active_ingredient character varying(60) NOT NULL
);


ALTER TABLE public.active_ingredient OWNER TO postgres;

--
-- TOC entry 4872 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE active_ingredient; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.active_ingredient IS 'у каждой характеристики есть активное вещество.Каждое активное вещество принадлежит лекарственной группе.';


--
-- TOC entry 218 (class 1259 OID 24629)
-- Name: drug; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drug (
    id_drug integer NOT NULL,
    trade_name character varying(60) NOT NULL,
    maker character varying(60) NOT NULL,
    form character varying(60) NOT NULL,
    dose_mg integer NOT NULL,
    shelf_life_months integer NOT NULL,
    price real NOT NULL,
    CONSTRAINT positive_price CHECK ((price > (0)::double precision)),
    CONSTRAINT positive_shelf_life CHECK ((shelf_life_months > 0))
);


ALTER TABLE public.drug OWNER TO postgres;

--
-- TOC entry 4873 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE drug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.drug IS 'у каждого продукта есть индивидуальная характеристика.У каждой арактеристики есть активное вещество.';


--
-- TOC entry 216 (class 1259 OID 24616)
-- Name: drug_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drug_group (
    active_ingredient character varying(60) NOT NULL,
    drug_group character varying(60) NOT NULL
);


ALTER TABLE public.drug_group OWNER TO postgres;

--
-- TOC entry 4874 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE drug_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.drug_group IS 'К каждой лекарственной группе принадлежат активные вещества.';


--
-- TOC entry 226 (class 1259 OID 24745)
-- Name: all_drug_information; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.all_drug_information AS
 SELECT drug_group.drug_group,
    drug_group.active_ingredient,
    tab.trade_name,
    tab.form,
    tab.dose_mg,
    tab.price
   FROM (public.drug_group
     LEFT JOIN ( SELECT d.trade_name,
            active.active_ingredient,
            d.form,
            d.dose_mg,
            d.price
           FROM (public.drug d
             LEFT JOIN public.active_ingredient active ON (((d.trade_name)::text = (active.trade_name)::text)))) tab ON (((drug_group.active_ingredient)::text = (tab.active_ingredient)::text)));


ALTER VIEW public.all_drug_information OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 24683)
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    organization character varying(60) NOT NULL,
    phone character varying(11) NOT NULL,
    inn character varying(10) NOT NULL,
    city character varying(60) NOT NULL,
    street character varying(30) NOT NULL,
    house character varying(10) NOT NULL,
    CONSTRAINT inn_check CHECK (((inn)::text ~ '^[0-9]{10}$'::text)),
    CONSTRAINT phone_check CHECK (((phone)::text ~ '^[0-9]{10}$'::text))
);


ALTER TABLE public.client OWNER TO postgres;

--
-- TOC entry 4875 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE client; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.client IS 'Клиент записан в транзакции , у каждой транзакции есть свой клиент';


--
-- TOC entry 221 (class 1259 OID 24667)
-- Name: individual_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.individual_product (
    sni character varying(20) NOT NULL,
    id_drug integer NOT NULL,
    storage_location_id integer NOT NULL,
    production_date date NOT NULL,
    CONSTRAINT checl_sni CHECK (((sni)::text ~ '^[0-9]{20}$'::text)),
    CONSTRAINT positive_production_date CHECK ((production_date < CURRENT_DATE))
);


ALTER TABLE public.individual_product OWNER TO postgres;

--
-- TOC entry 4876 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE individual_product; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.individual_product IS 'У индивидуального продукта есть место на складе.У инд.продукта есть свои характеристики лекарства.Каждый номер участвует в транзакции';


--
-- TOC entry 227 (class 1259 OID 24754)
-- Name: drug_desintagration_date; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.drug_desintagration_date AS
 SELECT individual_product.sni,
    drug.trade_name,
    individual_product.storage_location_id,
    ((individual_product.production_date + ('1 mon'::interval * (drug.shelf_life_months)::double precision)) - (CURRENT_DATE)::timestamp without time zone) AS time_to_terminate
   FROM (public.individual_product
     LEFT JOIN public.drug ON ((individual_product.id_drug = drug.id_drug)))
  ORDER BY ((individual_product.production_date + ('1 mon'::interval * (drug.shelf_life_months)::double precision)) - (CURRENT_DATE)::timestamp without time zone);


ALTER VIEW public.drug_desintagration_date OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 24628)
-- Name: drug_id_drug_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.drug ALTER COLUMN id_drug ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.drug_id_drug_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 24691)
-- Name: moving_drugs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.moving_drugs (
    id_transaction integer NOT NULL,
    sending_or_receiving boolean NOT NULL,
    cost real NOT NULL,
    phone character varying(11),
    CONSTRAINT cost_check CHECK ((cost > (0)::double precision))
);


ALTER TABLE public.moving_drugs OWNER TO postgres;

--
-- TOC entry 4877 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE moving_drugs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.moving_drugs IS 'У каждой транзации есть клиент .
';


--
-- TOC entry 223 (class 1259 OID 24690)
-- Name: moving_drugs_id_transaction_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.moving_drugs ALTER COLUMN id_transaction ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.moving_drugs_id_transaction_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 228 (class 1259 OID 24759)
-- Name: oborotii; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.oborotii AS
 SELECT client.organization,
    sum(moving_drugs.cost) AS oboroti
   FROM (public.client
     LEFT JOIN public.moving_drugs ON (((client.phone)::text = (moving_drugs.phone)::text)))
  GROUP BY client.organization
  ORDER BY (sum(moving_drugs.cost)) DESC;


ALTER VIEW public.oborotii OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 24644)
-- Name: storage_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage_location (
    location_id integer NOT NULL,
    line_storage integer NOT NULL,
    rack character varying(5) NOT NULL,
    shelf integer NOT NULL,
    box_storage integer NOT NULL,
    CONSTRAINT rack_side CHECK ((((rack)::text = 'left'::text) OR ((rack)::text = 'right'::text)))
);


ALTER TABLE public.storage_location OWNER TO postgres;

--
-- TOC entry 4878 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE storage_location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.storage_location IS 'У каждого продукта есть свое место на складе.';


--
-- TOC entry 219 (class 1259 OID 24643)
-- Name: storage_location_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.storage_location ALTER COLUMN location_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.storage_location_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 24717)
-- Name: transanction_decomposition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transanction_decomposition (
    transaction_id integer NOT NULL,
    product_id character varying(20) NOT NULL
);


ALTER TABLE public.transanction_decomposition OWNER TO postgres;

--
-- TOC entry 4879 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE transanction_decomposition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.transanction_decomposition IS 'У каждого номера пачки есть своя транзакция,у каждой транзакции есть свои номера пачек.';


--
-- TOC entry 4856 (class 0 OID 24606)
-- Dependencies: 215
-- Data for Name: active_ingredient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.active_ingredient (trade_name, active_ingredient) FROM stdin;
Vero-Netilmicin	Netilmicil
Руцектам	Цефтриаксон
Grimipinem	Имипенем
Bicana	Bicalutamide
Tizanidine	Tizanidine
\.


--
-- TOC entry 4863 (class 0 OID 24683)
-- Dependencies: 222
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (organization, phone, inn, city, street, house) FROM stdin;
Dynabox	3272092860	8061101714	Kuilehe	Stone Corner	24
Gabtype	5945314499	8858537785	Dong’an	1st	5
Zava	7626290912	6092773354	Chengdu	Buhler	52
Edgewire	3646185432	7025352193	Omišalj	Burrows	16
Feedbug	1014792919	8594507527	Bria	School	94
Youspan	8362949904	1421853542	Citeureup	Aberg	28
Realbuzz	6003258541	7525425239	Seongnam-si	Talmadge	9
Feedfish	3887496952	8995111667	Nahura	Emmet	51
Quinu	7203180822	9277569737	Mbinga	Huxley	76
Devpulse	5039808914	2444769155	Hujiaying	Garrison	87
Tazzy	2171461594	2175364451	Namwala	Anderson	63
Twimm	8099130557	1161114029	Haugesund	Londonderry	12
Photobean	4624440499	9303615919	Ojo de Agua	Vera	59
Riffpedia	4326115859	9332398287	Temblador	Schlimgen	77
Jamia	6304385417	8412406191	Guimarei	Oakridge	74
Realmix	6623600244	7125923531	Jūrmala	Artisan	18
Wordpedia	5416173936	5165109680	Oemofa	Nelson	65
Quinu	9602658540	2439764255	Chadian	Bartillon	8
Aimbu	8279065070	6817069698	Ḩuwwārah	Vidon	83
Yamia	5082864125	3774645222	Paitan Este	Scofield	46
Dabfeed	5018286620	7122092197	A dos Cunhados	Shelley	60
Oodoo	6574821960	7498986998	Cileles	Hazelcrest	12
Meedoo	5414574014	5693257023	Balekambang	Green	80
Fiveclub	3564355013	9005133926	Datian	Moose	72
Feedmix	8427542210	2601143516	Guamal	Scoville	58
Brainlounge	5553467371	8245656670	Sarykemer	Ridgeview	99
Skipstorm	1558093554	4173926365	København	Redwing	97
Zoovu	2121655989	7774155323	New York City	Eggendart	99
Edgeblab	6098173545	6396632254	Anping	Hovde	53
Browsebug	4997850630	2839005903	Qom	Village	6
Omba	2207738698	4643623757	Kremenets’	Old Gate	85
DabZ	1009054359	7101269986	Wupu	Division	26
Tagfeed	2151211156	3333400877	Philadelphia	Anthes	20
Wordware	8455010924	8624302662	Taketoyo	Barnett	49
Twitterworks	5295231368	9129108208	Khiv	Myrtle	13
Blogtags	3089001123	6931302888	Kamalaputi	Daystar	65
Fivebridge	8599024637	4651923428	Kedungbulu	Kensington	60
Jetpulse	9964560661	7672429390	Limeil-Brévannes	Rieder	30
Rhybox	2861469703	4847773078	Pomahan	Green Ridge	72
Digitube	3246669450	7156425241	Värmdö	Charing Cross	72
Zoomlounge	1539201626	9747409274	Laliki	East	49
Cogidoo	2624016182	6093267412	Trail	Miller	91
Agivu	8272115711	2789503456	Luleå	Ohio	15
Kwinu	4391359539	4729014799	Nizhniy Chir	Mcguire	41
Voonder	8165264473	6539274086	Los Charrúas	Rockefeller	67
Zoombeat	8049553389	1573422007	Iraray	Barnett	92
Eadel	9553305113	5877940917	Shengli	Glendale	75
Gabspot	4759911649	5686003662	La Dicha	Saint Paul	23
Divanoodle	3324335362	6385495296	Tsyelyakhany	Nevada	17
Cogidoo	9697615163	2347244548	Pojok	Acker	67
Babbleblab	9398054715	6972403770	Shuikou	Northwestern	42
Blogtags	4126358950	5743327275	Shuanglu	Haas	21
Thoughtbridge	4208054252	7558487066	Hufang	Crowley	56
Shufflebeat	6364412634	7501673152	Yuto	Acker	69
Ailane	8264942143	5155189811	Chamouny	Del Sol	49
Camimbo	1843869091	9118613779	Comalapa	Old Shore	49
Wikizz	4809129559	8659174735	Dingdian	Dexter	78
Zoovu	4211963455	9542020154	Xingyi	Karstens	27
Trupe	4328948175	8721988472	Sucre	Dawn	54
Snaptags	4792680958	8749118628	Sumurber	Bay	81
Thoughtbridge	7325060405	3102458873	Panggungasri	Delladonna	51
Tagopia	9836515217	4252734287	Ranot	Hooker	75
Topiczoom	7847925794	2304420599	Bachaquero	Monterey	7
Kazio	8904632561	9426364295	Strzelce Krajeńskie	Golf View	83
Dabtype	3744888124	4375760033	Tanda	Ridge Oak	84
Eabox	9181907692	7243361289	Khān Shaykhūn	Arkansas	45
Zoomzone	4841610573	8022429297	Zhaojia	Homewood	56
Wordpedia	8393497806	2623470951	Itaberaba	Dahle	32
Edgewire	2432484958	6597484112	Barranquilla	Texas	27
Yoveo	6705034171	5118647783	Ugep	Walton	51
Vinder	7067951428	1519925218	Ścinawa	Norway Maple	80
Twitterbeat	7092762735	3311585540	Paços	Veith	100
Yodel	7542743142	5387965203	Cuauhtemoc	Glacier Hill	15
Zoomlounge	4015939979	2666462601	Līvāni	Helena	92
Topiclounge	2192671062	8508279788	Gobernador Ingeniero Valentín Virasoro	Farwell	25
Jaxnation	2149585069	4084912973	Pilang	Bartelt	75
Zoonoodle	5615461261	3413520233	Kekeran	Pond	50
Twitternation	7403457072	2277786004	Igbo-Ukwu	Loeprich	65
Snaptags	3271588363	4127085901	Kawagoe	Esker	58
Ntag	4257153615	5478255011	San Isidro	Buena Vista	98
Buzzshare	4378156486	1744992840	Lucaya	Elgar	81
Feednation	5062817978	9424923452	Kalchevaya	Packers	36
Fanoodle	7985181928	8116645802	Shengshan	Rigney	24
Blogtag	8524575010	7594451656	Sundsvall	Sachs	64
Yodoo	9058732220	7721902507	Fort Erie	Rutledge	30
Feedfish	4634231738	2783291598	Samanco	Division	53
Riffpath	8429585960	9268989139	Juntas	Springs	19
Rhyzio	5237090601	1336343984	Wutongkou	Miller	44
Trudoo	1787483748	5686638924	Rābigh	Oriole	87
Realbuzz	1986949132	8179745578	Royan	Blaine	74
Layo	2661992676	6653805899	Tía Juana	Red Cloud	6
Oyoloo	2546627927	4156801821	Waco	Division	75
Blogtags	6217965684	3355277167	Novopokrovskaya	David	42
Tagpad	6052718192	2939532955	Manis Mekarwangi	Holy Cross	20
Dablist	3895439533	9712234516	Mariestad	Waubesa	80
Meembee	7225466619	8796890075	Yueyang	Rieder	87
Innojam	9906576311	6771290576	San Miguel	Stuart	72
Rhynoodle	5114820666	9965028127	Sumberdadi	Cody	23
Mydo	7194721987	9218864647	Piraí do Sul	Bluejay	59
Jetpulse	6125634524	3682895963	Minneapolis	Express	72
Divanoodle	6818746457	3919041646	Daliu	Brickson Park	83
Demimbu	3151740522	8513703058	Petropavlovka	Shasta	36
Realblab	9112169779	8681684641	Pivovarikha	Saint Paul	54
Ainyx	4129656668	1435101235	Damasak	Ramsey	69
Rhyloo	3515844954	1497570607	Kameyama	Sachs	6
Jazzy	2681859903	8417313981	Yepocapa	Tennessee	28
Yambee	4265994856	8964345638	Changning	David	45
Topicstorm	4325644504	2061390255	Langenburg	Meadow Valley	30
Edgeblab	4492838228	7431118499	Pokrzywnica	Banding	19
Topiclounge	3651543473	4581633288	Chicama	Prairieview	60
Devcast	6127281382	4599373845	Rodniki	Pearson	44
Ozu	7516285170	5575864649	Kankan	Anzinger	48
Twinder	9888874483	6019969742	Villa de Soto	New Castle	30
Flipopia	3093807453	9816732583	Ruzayevka	Mallard	15
Youspan	1231092193	8819385216	Cerro Azul	Oriole	68
Linkbuzz	4055598984	3434241687	Balugo	Daystar	29
Topicshots	4912886783	3216848695	Łagów	Morning	29
Realfire	7687870611	8523637707	Pinghu	Heffernan	95
Katz	4585098037	3151687858	Spandaryan	Boyd	94
Kazu	3566160723	6202699659	Khodzhi-Gasan	Shoshone	100
Gabtype	4094130268	4007556527	Patapan	Norway Maple	72
Jabberbean	9243374221	1108512495	Usab	Lunder	19
Katz	2912574114	5063717051	Qinā	Harper	85
Quimba	2825892618	4608839229	Esplanada	Merry	73
Realmix	8313929418	5026277362	Mora	Lighthouse Bay	27
Zoonder	8047700762	8128961499	Thaton	Anderson	12
Skipstorm	6695949843	1301244143	Enskededalen	Dayton	21
Chatterbridge	8052962373	4149444714	Tapiramutá	Towne	70
Aimbo	4699329895	7277748115	Jianxin	Ramsey	27
Linktype	2093153907	1934321570	Mġarr	Hayes	29
Eabox	8171509903	1041897002	Lazo	Everett	78
Dynabox	7259014393	9514718237	Capanema	Buell	19
Midel	9536881338	6143904267	Yanda Bayo	Nancy	80
Voonix	3673282719	6089367256	Krasnokamsk	Scott	97
Kwilith	2698057541	1367719223	Likhoy	Dunning	20
Flipopia	9525497064	1304829693	Young America	Dorton	57
Brightdog	6465727058	9628080913	Gaoshan	Steensland	6
Devshare	9635964411	4838106135	Jianshe	Toban	86
Buzzdog	5104956700	4742355580	Indulang	Beilfuss	5
Tagpad	3329187445	8313088388	San Francisco	Corscot	17
Zoomzone	6363859318	2907331039	Chadong	Corscot	28
Yozio	3411842898	8595965509	Mitrofanovka	Blue Bill Park	91
Jaxspan	9153510479	2709223647	El Paso	High Crossing	98
Oba	1146705079	5283661198	Bayshint	Milwaukee	20
Geba	6356788512	8864012689	Arsen’yev	Bunker Hill	29
Browseblab	3928559026	4218055622	Golubac	Kipling	70
Fivespan	1856365400	2368369531	Olocuilta	Anniversary	43
Wordify	8649085981	2857441304	Mersa Matruh	Commercial	68
Quaxo	3467237729	7069055480	Miranda	Gateway	30
Kanoodle	8091601034	7726064653	Ami	Vidon	17
Ozu	4089662631	4854692612	San Jose	Rockefeller	41
Thoughtstorm	8916871892	3969506264	Älvsbyn	Fulton	69
Eamia	1376507299	2991549600	Rodez	Iowa	84
Dynava	6735137353	4615540188	Bích Động	Darwin	27
Dynabox	6475369506	6222191369	Futian	Logan	93
Jaxspan	9357771800	3189702711	Sassandra	Eliot	100
Thoughtstorm	1184479470	4557855003	Adelaide Mail Centre	Roxbury	35
Realbridge	6261943959	7306319279	Cabra Figa	Welch	6
Rhyloo	4498799887	3216570169	Xikou	Russell	60
Mymm	5776090192	1499224900	El Aïoun	Service	66
Oyondu	1351717023	2362641607	Markaryd	Rusk	45
Linklinks	9978835059	7641095242	Phan Thong	Artisan	87
Fliptune	5984618071	9355356260	Daleman	Rigney	48
Bubbletube	3426303729	2894531069	Chavarría	Everett	31
Zoonder	5629265405	2088108781	Longwei	Melody	84
Avamba	4025167203	3649986675	Nevel’	Eggendart	13
Twitterbeat	2576783996	7158871219	Lakshmīpur	Arizona	93
Jaxbean	3313720402	8247288119	Boavista	Anthes	68
Podcat	1323000487	7658662079	Meukek	Elka	49
Thoughtstorm	6983748006	9226167877	Orléans	Roxbury	55
Zooveo	9976759129	6744895167	Las Garcitas	Clove	67
Plambee	9141105384	8018881144	Carodok	Trailsway	47
Eamia	8568944355	5855377207	Malanville	Quincy	96
Mydo	8383852162	4486758336	Xin’an	Chinook	9
Devshare	3935962387	4354679452	Akkol’	Boyd	92
Oyoba	9448016128	6429372410	Chwałowice	Hanson	51
Skilith	2526360591	3242863854	Yeni Suraxanı	Kingsford	16
Quamba	6676381373	7509070068	Independencia	Randy	17
Skyble	2538436210	4346821743	Pacucha	Union	20
Edgepulse	8973992390	8379241995	Dahu	Artisan	55
Wikizz	6354414748	9677258404	Sidomulyo	Fulton	31
Agivu	8728082934	1693621711	Shireet	Cherokee	100
Rhynoodle	4555283751	7991922843	Bełsznica	Kings	7
Jabberbean	8598769417	8103231053	Lexington	Anzinger	32
Kwideo	3167187682	9863856028	Vatutino	Reinke	94
Meevee	3059896184	6095674112	Tangkeng	South	37
Twimm	3195409074	4173103147	Xixi	Lillian	76
Teklist	8377017784	2191723360	Jianshe	Pennsylvania	99
Yodel	4318903033	5556612141	Vicente Guerrero	Hudson	37
Feedbug	9912101362	7653401567	Borucin	Paget	32
Tavu	7021735996	5486374981	Konkwesso	Spenser	7
Topicshots	8867461509	2049923726	Ishkhoy-Yurt	Hanover	10
Vinte	3101795825	9257924347	Santa Monica	Mariners Cove	65
Cogidoo	7167879338	1177865665	Buffalo	Nancy	50
Linktype	5472964736	2633133610	Brody	Algoma	94
Thoughtblab	3478101503	1839418448	Bantardawa	Rutledge	43
Leexo	6211926423	1151399570	Veles	Autumn Leaf	85
Yoveo	4828225162	7981469665	Xianghua	Londonderry	64
Photospace	6759024078	8631408967	Panyindangan	Northridge	81
Bluejam	1691723964	3805809123	Hailang	Marquette	81
Topicshots	8137478414	2937001722	Muang Sam Sip	Marquette	11
Photolist	8312059962	3378821105	Novovarshavka	Roth	90
Reallinks	4782417631	1304634910	Savannah	Anhalt	58
Camido	3667330420	1732739660	Peliyagoda	Bartelt	93
Yabox	7108968962	7388676448	Nong Ki	Westridge	93
Quire	1064243997	8332119126	Loufan	6th	67
Buzzster	9188317580	9423253836	Roa	Warbler	61
Livetube	2421675156	2645291995	Humniska	Loftsgordon	86
Realcube	1263398503	5229145693	Tangdong	Rutledge	87
Yabox	7793504818	4472882097	Moshenskoye	Fallview	67
Trupe	5854622316	1417980670	Sehwān	Meadow Vale	100
Rhynoodle	1153001202	8694696836	Yakimovo	Del Sol	41
Rhybox	6531406206	6725980717	Ichinohe	Mallory	34
Voomm	6199819562	2982845686	Gudong	Twin Pines	55
Quatz	7719812194	3083292299	Krajan Sumberanget	Browning	13
Innojam	3488632870	7049838296	Zhangcun	Cherokee	25
Kwilith	5834425883	5953308742	Chengbei	Mandrake	72
Skibox	3356007255	7784677661	Quemú Quemú	Badeau	20
Skipstorm	2969872769	9045460923	Ngroto	Jackson	20
Roodel	2997864998	6334131313	Targowisko	Springs	13
Viva	6269773219	7773633571	Gubkinskiy	Merry	22
Browseblab	2973203837	5109601298	Aulnay-sous-Bois	Springview	60
Flashspan	8511071853	6903127113	Kynopiástes	Roxbury	86
Youbridge	1663482393	1118646733	Kuteynykove	Sommers	99
Gigabox	6903957061	3514547154	Bonik	Ohio	75
Dazzlesphere	4369396802	3479258982	Kapitanivka	Claremont	13
Zoomlounge	2508939627	7816378101	Lesichevo	Bluestem	98
Thoughtbeat	2663778343	5229735146	Situ	Buhler	20
Gabvine	2122893316	6109026592	New York City	Starling	8
DabZ	3356492405	2528670350	Xiaojinkou	Vernon	54
Katz	6792927951	2802084278	San Vicente	Ridgeview	81
Riffwire	9384847458	3343569136	Alagoinhas	Debra	17
Skyble	3162642058	6625291916	Shatrovo	Kipling	89
Wordpedia	6894091393	5091463759	Viedma	Hollow Ridge	17
Youopia	1591078548	1808312104	Toul	Kings	54
Pixonyx	5388279770	8864666540	Dukuh Kaler	Erie	94
Kwilith	7711970177	4339316841	Blagoveshchensk	Sugar	17
Browsezoom	5771629331	2803268561	Ichuña	Bunting	68
Vimbo	5265626088	1302971925	Shuyuan	Bowman	83
Flashset	8901121413	8116423442	Krajansumbermujur	Schurz	50
Dablist	7123479238	3889703590	Berlin	Mccormick	31
Tagchat	1881828915	5664173657	‘Arīshah	Anhalt	63
Photofeed	1058647231	2992967972	Butiama	Southridge	11
Oyoyo	7347950415	8564690720	Ximapo	Huxley	47
Lajo	6392333977	9946635516	Pýrgos	Carey	12
Demivee	7609089234	5117207966	Rouen	Jay	25
Realcube	2948186963	4416861356	Gexi	Swallow	20
Voonyx	3962848490	8405650066	Igarassu	Monterey	78
Twitterbeat	1178471934	8651680831	Rizal	Towne	45
Quinu	7116167385	6085871910	Zhongshan	Eastwood	44
Gabtune	6417745480	1269129648	Paulo Afonso	Sunbrook	61
Linkbuzz	7494494817	5153815667	Icó	Hoffman	75
Mycat	4392426762	4434246523	Kalnibolotskaya	Dayton	22
Skinder	7003071776	6486533479	Az Zaytūnīyah	Sommers	98
Yotz	1958904112	1023772530	Pukou	Columbus	25
Tagopia	5245541598	5482579714	Yinjiacheng	Farwell	42
Dynabox	8874523241	9515114215	Cauto Cristo	Norway Maple	29
Linklinks	2142724920	8401529179	Ağdam	Melby	38
Wordpedia	7024891668	9509099676	Las Vegas	Mallory	88
Devpoint	7081341825	1658370957	Cuijiamatou	Nevada	38
Quatz	9785488605	9686575877	Oslo	Sage	54
Buzzbean	8832280122	3192068953	Vicente Guerrero	Mayer	42
Eazzy	3869516952	5185364396	Fatikchari	Dunning	82
Realcube	2277153786	2761090832	Ledoy	Mcguire	82
Pixope	9585476083	2651875360	Khe Tre	Bayside	56
Gabtype	9348426926	4137597247	Rubirizi	Little Fleur	47
Gigashots	8255592244	7098902559	Namasuba	Kennedy	7
Shufflester	4996155014	6892838381	Zhangping	Kensington	40
Rhybox	6951325051	7189264846	Minian	Ronald Regan	9
Dynabox	2173428025	8124343751	Mutum Biyu	Blackbird	24
DabZ	6917628112	8324618289	Heling	Mosinee	53
Gigabox	7016398061	5861921298	Góra Kalwaria	Little Fleur	100
Jabberstorm	2702019005	8688969346	Lazaro Cardenas	Drewry	37
Meemm	5429838004	2575272815	Kitimat	Troy	31
Divavu	9132587691	6853558715	Gent	Elgar	92
Bubblebox	6175170524	6167773982	Krasnaya Gorka	Warner	74
Twimm	4842539207	7711909728	Puerto Berrío	Schmedeman	71
Skimia	8614933154	4984627901	Bestala	Village Green	28
Avamm	6134354545	2706387220	Batatais	Utah	21
Twimm	5909512020	7866538319	Tsubata	Lien	91
Buzzdog	6057170169	4832839726	Stírion	Browning	87
Photolist	9411831388	8922070891	Kapotnya	Derek	34
Plajo	7546103729	4407869617	Zhaojia	Springview	100
Rhyloo	8803560704	6709895737	Xincheng	Ridgeview	23
Avaveo	4182267150	2337500039	Lyon	Fairview	94
Feedfire	4228447330	7994446558	Damatulan	Prairie Rose	18
Edgetag	9163231348	7294409888	Laâyoune / El Aaiún	Iowa	39
Rhybox	7041887962	6281669098	Brunflo	Bluejay	29
Feedfire	3008012948	6489926457	Smolenskoye	Esch	56
Photospace	4047156591	6913977562	Duluth	Prentice	77
Feedspan	9574692037	1853926492	Darenzhuang	Eastlawn	13
Centizu	4539849615	8743846923	Saint-Lin-Laurentides	Hauk	40
Tagpad	7993841582	8019341858	Moneague	Jenna	61
Dynabox	3487117168	8527951957	Senj	Melvin	21
Flipbug	1123978160	2199230057	Xiangjiazhai	Shelley	66
Muxo	8755696811	7916412830	Noyakert	Birchwood	23
Aimbu	9616457745	8466833952	Helmas	Clove	9
Trupe	5487037120	7791391547	Buchanan	Roxbury	56
Photolist	1224835468	2732243889	Perelhal	Dennis	23
Thoughtmix	2874706634	5199812457	Palaiochóri	Meadow Vale	35
Thoughtsphere	8902932651	9114829968	Tākestān	Algoma	37
Browseblab	3591586569	2069567871	Babo-Pangulo	Mandrake	77
Flashspan	9657561975	1214788275	Cap-Santé	East	46
Blogtags	2115780478	4475792937	Dahuaishu	Lakewood Gardens	64
Thoughtsphere	8148360947	5565127086	Prokop’yevsk	Loomis	73
Trupe	6603851277	7052452024	Nianpan	Troy	7
Gigaclub	5471414477	3657851418	Dongji	Monica	68
Rhybox	2524459888	1765168003	Sunzhuang	Stephen	72
Kayveo	6393528795	8459886074	Rushankou	Cardinal	65
Realcube	8243131158	1114510145	La Fortuna	Forster	15
Mydo	7632072068	5275699535	Maojiagang	Sommers	78
Skyndu	7578225780	9039736941	Alma	Ruskin	58
Roomm	8021827429	9989528027	Alcácer do Sal	Parkside	42
Rhynyx	6043903531	6618076471	Narong	East	10
Wordify	7348709664	6088958508	Pensilvania	Village	14
Topicstorm	1714258580	5982594757	Atlasovo	Bashford	30
LiveZ	2014320617	8508084436	Strömsund	Farragut	5
Jabbersphere	9382875819	3438708619	Chaplygin	Bellgrove	58
Trupe	3073426727	5804207290	Zhaobaoshan	Mayfield	62
Divavu	8756852162	8152412043	Bunobogu	Jenna	56
Blogpad	2093460870	8226317644	Nakhon Si Thammarat	4th	39
Quamba	9123064004	5944368648	Drummondville	Springview	37
Twitternation	9024863263	5577378310	Bonao	Lake View	79
Divanoodle	6138303024	2366612585	Kumanovo	Grasskamp	87
Feedspan	2766081492	1713933734	Pujiang	Veith	58
Jaxspan	8846489209	8778581071	Margita	Russell	83
Oozz	3395078230	4125967728	Pasian	Wayridge	9
Izio	3482033732	1239230287	Dubá	Cordelia	11
Npath	8325293792	1796183073	Mutā Khān	Helena	91
Dabjam	4259471318	8222906150	Temirtau	Blaine	23
Realcube	8023171378	8946573197	Patrocínio	Anniversary	42
Centidel	9726441515	2087038373	Otavalo	Farwell	16
Realbuzz	6872451362	9907002436	Saint-Quentin-en-Yvelines	Harbort	72
Linklinks	6224502787	3508378879	Baitouli	Sunnyside	18
Meetz	3466601382	6282265397	Nanjiao	Kings	24
Divape	7824340522	2481396675	Calamba	Dorton	51
Yamia	1742261492	3375259350	Ninghai	Ohio	18
Youopia	5974658644	1345502764	Calinaoan Malasin	Paget	21
Oyoyo	1497554952	4935885483	Tuopu Luke	Browning	18
Browseblab	5146618149	5441711900	Qobustan	Oneill	20
Realbridge	3482057075	5874653447	Uścimów Stary	Goodland	21
Babbleset	2033466765	3807178110	Dongcun	Barby	30
Babbleset	6923510168	2362722080	Glugur Tengah	Dottie	49
Muxo	3128966286	9469208429	Zavet	Meadow Ridge	74
Youfeed	3602803553	1027954019	Şabāḩ as Sālim	Little Fleur	66
Photobug	1141746423	1948013416	Aygestan	Knutson	94
Flashpoint	2836429294	6624203628	Dobříš	Bartelt	80
Oyope	5421970405	7892852978	Loučeň	Northwestern	6
Eayo	9031689869	3382076909	Takaishi	Kinsman	92
Dynabox	1685070386	6413769691	Yucheng	Straubel	94
Skimia	6463927840	2431414290	Shāhīn Dezh	Clemons	68
Myworks	6276448037	4607109007	Fernandópolis	Sloan	85
Cogibox	9769891513	5879676382	Pokrzywnica	Carberry	46
Yacero	3531868563	1876445054	Fotolívos	Mallard	88
Youbridge	6226822934	6864208803	Farriar	Meadow Ridge	89
Eayo	7948329043	1565978248	Khlung	Ohio	80
Jayo	8203071562	2642662684	Alimono	Mesta	54
Dynazzy	9691584312	3851724834	Dome	Linden	12
Eare	6715013072	6105667184	Kalloní	Rutledge	36
Ozu	4151444459	5018919505	Māmūnīyeh	Scofield	12
Latz	8518436268	3053087278	As Sūq al Jadīd	Nancy	74
Lazz	7252770366	7538479106	Ouégoa	Westridge	45
Mycat	6212438771	2961939632	Kukawa	Bonner	13
Eire	8251948425	7402190995	San Bernardo	Glacier Hill	74
Twitterwire	7426238156	8151105573	Svetlanovskiy	Sutteridge	34
Demimbu	9927388263	6264907098	Segovia	Corscot	99
Realcube	3445463912	7972045342	Dillenburg	Nova	59
Dynazzy	5884877924	1114440014	Al Qardāḩah	Burrows	75
Flashpoint	7301045260	3037991915	São Luís de Montes Belos	Prairieview	23
Youspan	9205871972	4126355330	Shishan	Summit	61
Bluezoom	4096133322	5127307346	Xinjian	Arkansas	64
Kazio	9411662419	2462543060	Jacaltenango	Quincy	42
Jamia	2091598842	2108642134	Laoliangcang	Hazelcrest	79
Podcat	9861259540	9483103161	Akaki	Waywood	94
Cogidoo	9819187575	3731429345	Amurzet	Golf	57
Mynte	6887870539	4186545863	Kozhanka	Division	25
Feedfish	8047060651	7755713832	Fasito‘outa	School	15
Topicware	1048296501	5763989249	Autun	Springs	66
Blogtag	2371665065	5936616407	Kota Bharu	Sutherland	40
Oozz	6132557719	7036565002	Pokrovskoye-Streshnëvo	Cottonwood	32
Roomm	3823222198	1974259244	Bojonglarang	6th	64
Blogspan	2161683643	1449935061	Lakha Nëvre	Mcguire	15
Eamia	6404462639	2858205978	Al Ḩawāmidīyah	Scoville	81
Avavee	5114326039	4235229344	Majur	Maple	91
Jamia	7157026220	6318585890	Armstrong	Bayside	71
Topicblab	7595697164	7227029644	Banqiao	Di Loreto	65
Pixoboo	7133178691	5087052215	Sandefjord	East	21
Voolith	9189105679	4969046543	Caçapava do Sul	Claremont	60
Eimbee	3791303183	6668962738	Yamoussoukro	Bowman	10
Janyx	7701558262	6368267914	Okulovka	Warrior	81
Realbridge	9413093927	3667732529	Sumiainen	Riverside	53
Kazu	1558997612	8573649314	Mozdok	Chive	15
Janyx	5576210309	8137475477	Concepción	Pennsylvania	80
Eabox	4664585386	3103217291	Tarxien	Schurz	75
Janyx	6072134284	3151289105	Mandapajaya	Bellgrove	88
Meemm	6468442219	1851791695	Kōfu-shi	Iowa	44
Meezzy	1296271635	9286209877	El Calvario	Blackbird	27
Rhybox	4458251626	7092999044	Bobai	Mariners Cove	72
Dablist	4155318408	4041959013	Monte Agudo	Blaine	33
Realfire	4715845548	2711080243	Denyshi	Bunting	8
Rhynoodle	2516063635	9691538753	Mobile	Havey	33
Yadel	7167773850	1228548491	Caotang	Atwood	99
Shufflebeat	5131077873	7485200058	Águas Vermelhas	Jay	27
Riffwire	8242924095	1347246642	Masaran	Bultman	36
Bubblemix	7074294523	3522968688	Tlogoagung	Eastlawn	13
Kamba	5082181214	6453010994	New Bedford	Maple	16
Yoveo	5286681493	1326120903	Srpska Crnja	Karstens	17
Topiczoom	5696108773	5729614683	Al Marsá	Grim	44
Linktype	8896198555	9904125691	Nagornyy	Truax	63
Babbleset	8028799314	9815067950	Siva	Aberg	11
Photolist	9127133845	2196670688	Fundación	Claremont	80
Wordtune	6393063971	6416454647	Asahi	Meadow Valley	59
Vipe	6479558729	7255398092	Dolní Cerekev	Maywood	14
Agivu	5858762874	4097032423	Fonadhoo	Arizona	75
Kare	4945930063	6608577705	Kourou	Fairfield	88
Youopia	7321945032	5198242644	Komatsu	Shopko	48
Meevee	5965247191	6134756773	São Sebastião	Hallows	89
Yombu	8916618746	3606559256	Yingtou	Golf Course	19
Flipopia	4576756986	7878912579	Likhoy	Pawling	41
Yadel	1325003074	3043117708	Karangnongko	Stone Corner	51
Kazio	4967853399	1983259878	Wŏnju	Dunning	20
Thoughtstorm	9298716661	9843838561	Gonzalo	Ludington	16
Riffpedia	8031220360	9797143933	Ustynivka	Bluestem	83
Janyx	8826085344	7551933230	Kladovo	Reinke	53
Photobean	9454613723	5216079741	Zyryanovsk	Westerfield	34
Vinte	9779360005	3488368259	Balongmulyo	Jackson	24
Skilith	3941044845	5547731776	Xiangzhou	Sullivan	76
Eamia	2468686203	9087346045	Binubusan	Longview	97
Brightbean	3029884805	8123997591	Wilmington	Sherman	9
Tanoodle	9935973089	6751094348	Xiaqiao	Veith	31
Dablist	8796695924	3516669156	Ludbreg	Service	72
Devpoint	2386193632	3834767365	Leninskiy	Schmedeman	78
Yabox	9442573713	9955068896	Kamsack	Lawn	68
Mita	4466398207	2775064008	Bello	Manley	43
Zooxo	2149855120	3934763343	Dallas	Morrow	98
Brainbox	2519371945	8637686104	Zherdevka	Melrose	7
Kwimbee	3571810321	1973233932	Atescatempa	Artisan	51
Centimia	4879435059	9365478101	La Unión	Main	77
Quaxo	8076679592	6637826328	Mława	Dunning	79
Topicware	8219254801	3733303648	Urzuf	Starling	63
Feedbug	9532532910	9557696915	Perugia	Nancy	12
Kazu	3565096565	9728261682	Nabire	Logan	45
Wordify	7918105520	9156176863	Shiyang	Amoth	63
Cogibox	2988963283	5372888696	Prienai	Division	77
Yombu	1843411992	3155747802	Riosucio	Elmside	81
Quimm	9759917737	2773040384	La Calera	Dapin	87
Snaptags	4781935632	5816168496	Qarqania	Melody	91
Npath	8661208209	2561250907	Aral	Talisman	49
Katz	3761578356	2982083146	Nuevo Amanecer	Carioca	42
Shufflester	6796440183	1169419757	Girang	Farragut	55
Skynoodle	9362808407	5709361981	Khvānsār	Fisk	6
Geba	8174824869	2683319586	El Tabo	Delaware	21
Izio	4945844798	7696869015	Sankui	New Castle	24
Youspan	5316272178	4953352941	Jaruco	Birchwood	92
Mydo	9394325509	2639976278	Gagarawa	Lerdahl	18
Buzzdog	9017015731	8806015801	Sexiong	Messerschmidt	44
Yodoo	8945401413	1909398440	Bahāwalpur	Green	28
Flipstorm	3372245964	3714249478	Huazangsi	Kingsford	13
Kazio	7214206476	6806307087	Pappádos	Sauthoff	75
Kwimbee	8554448156	8563594382	Orissaare	Cascade	40
Fliptune	2035274447	2087757958	Sokarame	Algoma	73
Eayo	4151174716	3141669865	Oakland	Raven	9
Quatz	3826673103	3185727175	Odivelas	Oak	45
Realmix	5163914725	5544110170	Périgueux	Hayes	78
Vinte	2803862805	6783857091	Rungkam	Boyd	43
Oozz	7157695798	3143269066	Hanlin	Dovetail	93
Thoughtblab	9545790261	7695193648	Jilong	Luster	30
Jaxspan	7494746282	9035028699	Kapotnya	Del Sol	92
Pixonyx	6017830078	9696378395	Ashikaga	Chinook	9
Linkbridge	7085376581	8755423223	Radeče	Arrowood	69
Voolia	3741091296	8678148994	Zhengchang	Montana	19
Browsedrive	6025539168	2077079583	Marādah	Kipling	97
Devcast	7755271322	6571056832	Pico Truncado	Marquette	6
Skajo	4001061718	4956708789	Jielin	4th	68
Quimm	8677317827	3324539931	Antiguo Cuscatlán	Bunting	16
Rhybox	3354518194	4666190577	Tuplice	Trailsway	73
Npath	9277481529	2831886757	Ganting	Service	89
Realpoint	5832721078	1312288326	Leninskiy	Schmedeman	6
Linkbuzz	3819860925	9869785226	Tanjungbahagia	Monterey	36
Yakitri	4841176402	9073710228	Santa Lucia	Fair Oaks	8
Nlounge	1018507240	8123195184	Ruyigi	West	34
Plambee	2647628214	4507289353	Cabangan	Center	17
Demizz	9147027363	7501425565	Tiandu	Lukken	9
Fanoodle	1096077674	7333382488	Xinglong	Rusk	8
Flashpoint	3176848862	6479119335	Krasnaye	Birchwood	71
Meedoo	5532380785	1714698054	Primorka	Kenwood	40
Thoughtbridge	9485400605	7908568383	Pentaplátano	Hermina	64
Skimia	1426354434	1156814236	Pagangan	Prairie Rose	6
Skajo	1048878401	2703052356	Jājarm	Myrtle	8
Topicshots	6852347850	8668978527	Juyuan	Pankratz	48
Gabtype	5878054287	4708828356	Jinshan	Shelley	66
Brightbean	1245073538	4062028957	Ostrowsko	Northview	50
Fanoodle	3141486705	6262021089	Saint Louis	Hayes	65
Rhynyx	8723170725	9935911759	Sepanjang	Hayes	98
Kanoodle	4133054179	4639016139	Molugan	Sachtjen	68
Yakijo	4017253363	1512328306	Mamponteng	Kings	86
Teklist	2997281760	6045425500	Lokokrangan	Bowman	71
Blogtags	1206110983	7567894091	Holýšov	Del Sol	69
Voonte	7532131155	4495980534	Lin’an	Delaware	88
Kazio	3789406474	3855385059	Xiangzikou	Stone Corner	39
Jaxnation	3834918442	4563265576	Lumil	Anhalt	78
Centidel	4513157764	1265931378	Seremban	Killdeer	65
Feedspan	8467417169	2329233842	San Luis	Shelley	68
Trudoo	3205152340	1589975101	Las Palmas	Scofield	76
Zooxo	8054854094	7874097994	La Paz	Larry	60
Tekfly	1548319062	6851240058	Umingan	Roth	28
Fatz	2071039882	6265709628	Cijengkol	Forster	61
Janyx	2051102156	1135649544	Wangping	Surrey	95
Quatz	1539997927	1185106087	Lokavec	Declaration	96
Browsezoom	9966901445	7485270305	Pilang	Miller	79
Skiptube	2381991111	8747116059	Bous	Union	56
Wordtune	9858543757	5072478005	Zishan	Rutledge	28
Oodoo	6016791371	3099120076	Štěchovice	Upham	13
Quimba	2166318249	2902820364	Tagnanan	Quincy	21
Kayveo	9121328061	3321315582	Kozova	Graedel	7
Realmix	6763848468	8294533681	Wiang Chiang Rung	Merrick	75
Rhyzio	7782563369	5973240871	Tuochuan	Novick	32
Edgetag	9594877932	1018319009	Ancenis	Schiller	93
Twitterbridge	6578859687	6187871963	Ejidal	Union	41
Shuffletag	2148153631	6968391794	Dankalwa	Quincy	40
Skimia	3829811387	5534374931	Zhangpu	Hoard	46
Demimbu	4836532563	3938599747	Rizal	Atwood	70
Nlounge	9314817760	2934185357	Huangdu	Warbler	38
Eayo	3169358676	4217127823	Chervonohryhorivka	Everett	90
Agimba	6215023273	6835848155	Cruzeiro	Lakewood	45
Kwimbee	1793585454	7012046821	Lens	Nevada	28
Trilia	8679328968	6199290423	Viljakkala	Kingsford	16
Shufflebeat	2903450966	7494772085	Heting	Pearson	41
Eimbee	6693914590	7773671201	Tongguan	Redwing	49
Topicware	9397121021	2677952424	Fenglai	Wayridge	48
Lazz	8627428280	5027487328	Aliwal North	Clarendon	37
Trunyx	8381981251	4475340334	Tromsø	Lake View	22
Oyoyo	6559027992	2133400854	Wola Rębkowska	Bay	47
Edgeify	1855680972	1431711948	Dzüünbulag	Prairieview	33
Riffwire	5935674963	3132953099	Mulyoagung	Eagan	91
Gabtune	6427238879	6915004510	Qingfenglin	Dapin	35
Mynte	3087697056	8791604069	Khvatovka	Claremont	19
Snaptags	8141888449	8733292484	Doghs	Sundown	28
Realbuzz	7998772866	9187371021	Haizhouwobao	Lukken	92
Rhyloo	2774978643	6758477184	Batan	Comanche	8
Wikizz	9857109140	5468146806	Nova Prata	Vermont	100
Youopia	3505344512	4701065966	Zhiryatino	Harper	28
Topicshots	3656086500	8086977088	Guxi	Dahle	41
Youfeed	1287227331	8224154792	Leksand	Transport	66
Kayveo	8187342429	3737400889	Siedleczka	Di Loreto	14
Jamia	8392547695	9457650053	Road Town	Grayhawk	88
Thoughtsphere	8041095506	5845007272	Gobō	Eliot	29
Thoughtbridge	9606051478	9899314544	Genang	Dahle	17
Dabvine	6018328128	4332085024	Sankui	Northport	38
Brightbean	7592843949	5663987649	Bendoroto	Manufacturers	89
Quatz	4483238746	6121491367	Laiya	Sugar	63
Mybuzz	9093685510	3899160942	Aniso	Green	13
Lazz	9248058144	2128002275	Gilowice	Buhler	74
Tagchat	1576112746	1008444124	Uijeongbu-si	Oak	11
Blognation	8498406462	8984891219	Asempapak	Pankratz	80
Yakidoo	1775317452	7018267763	Bagdadi	Spenser	89
Wikibox	6235436149	4376871524	Bijeli	Troy	18
Thoughtmix	1492349169	3398672141	Khamyāb	Packers	36
Innojam	9768241948	8463898628	Cruz Alta	American	98
Devshare	2615745735	7951268831	Wangchang	Annamark	55
Divanoodle	3966042655	8365509268	Kalinovskaya	Bowman	42
Dabshots	2562273037	4881694522	Braunschweig	Susan	49
Tagopia	6614187681	1969276236	Grajaú	Petterle	32
Fiveclub	8602638563	7832996591	Xingzhen	Mariners Cove	24
Jatri	2065831392	6879106065	Camperdown	Rusk	91
Jabbercube	9601066259	2601993109	Yên Thành	Graedel	59
Centidel	9516706943	7384780480	Mường Nhé	Hansons	86
Roodel	4253714311	4833244806	Eckerö	Erie	99
Yacero	1506835403	9764681801	Ancasti	Johnson	86
Skilith	7252160245	7969727923	Nabunturan	Rieder	93
Quimba	2615796239	9213767199	Taiping	3rd	40
Edgewire	9855873978	7459127448	Liudu	Rowland	7
Ailane	3906506079	1701586742	Mengxingzhuang	Gina	22
Zoomcast	3302277821	4368686916	Tapas	Jenna	32
Trilia	4243178285	8187745048	Axili	Rowland	90
Demimbu	7298828769	4444601997	Jindong	Sutteridge	77
Pixoboo	8708802927	5145693508	Vratsa	Debra	15
Demivee	4749874298	1776254668	Sena Madureira	Raven	33
Camimbo	9201971034	2309882714	Cruzília	Manley	53
Tavu	1489832301	1418890732	Timahankrajan	Meadow Ridge	75
Thoughtstorm	9068731254	9181167127	San Pedro One	Dorton	45
Livepath	5712760451	9769796387	Diepsloot	Crownhardt	17
Quinu	2303202363	9739357041	Maguan	Mcbride	67
Avamba	5206427198	8973841238	Raychikhinsk	Village Green	57
Meeveo	9242631057	4211775612	Solnechnoye	Fordem	71
Yodel	5889075029	8577576167	Kamyshin	Jenna	94
Vitz	1944643494	1108034032	Suwaduk	Grover	39
Blognation	9836771108	1682217423	Guinabsan	Cardinal	98
Mudo	9577885372	7503871470	Sharga	Chive	82
Thoughtsphere	9797302544	1211604430	Sapareva Banya	Hanover	15
Thoughtblab	1412380656	6318624714	Gort	Forest	70
Feedmix	8685422750	5862796246	Pagelaran	Waubesa	90
Eare	4404164486	3665049612	Zongga	Rutledge	75
Skipstorm	4467741934	3968456368	Huta Stara B	Schlimgen	89
Flashspan	5378195974	3484713021	Longsheng	Miller	48
Dynabox	1293857352	2323056184	Stockholm	Grover	100
Zoomcast	5188564307	5643474247	Sundumbili	Sloan	58
Yodo	1303198777	8766913303	Lebu	5th	57
Aimbo	2975010767	4531712604	Zhongben	Fisk	85
Blogtag	4644373989	4302107730	Hengjing	Debs	5
Meejo	3154483088	2022393206	Cabedelo	Graceland	65
Vimbo	6077657408	5762521063	San José	Canary	55
Yotz	3857064020	9844369299	Zhangfeng	Chinook	42
Shuffledrive	5489281298	5307506214	Yanghu	Prairieview	20
Latz	8528523141	5112242349	Vnorovy	Forest Dale	71
Cogidoo	4351076605	3512209516	Nazran’	Esch	89
Leenti	2072740077	9067241372	Jinsheng	Vernon	75
Devbug	2091971880	1817526381	Tagapul-an	Veith	80
Yodel	2689446499	8691355210	Aiquile	Pankratz	81
Mymm	9137411673	2969608948	Shawnee Mission	7th	87
Muxo	2292940077	1436802958	Bashan	Norway Maple	37
Ntag	3373429666	8459404377	Babantar	Arrowood	11
Jayo	3014961615	2775569374	Carapelhos	La Follette	6
Aivee	2163957487	7214707999	Suhe	Kropf	97
Yotz	4788035408	9866724140	Temperak	Cascade	74
Jabberbean	7143676191	9218069903	Huntington Beach	Mallard	98
Meevee	3405817585	1947158765	Ambat	Lillian	21
Yamia	9327853627	2465133063	Machov	Golf	85
Oyonder	5988133843	6221872943	Golem	Jay	10
Brainsphere	8973420735	7643201390	Desnogorsk	Anderson	95
Linktype	2465838850	4497805520	Heyu	Cambridge	73
Flipstorm	9663210635	9951087273	Chernomorskiy	Rutledge	53
Topiczoom	1635886052	2725846563	Kuching	Sunbrook	79
Jetwire	9627309179	5409688704	Neochórion	Mayfield	9
Mybuzz	3683603379	2829079647	Ia Kha	Delaware	36
Photolist	6139552904	2298467775	Colmar	Northridge	32
Realmix	1024343092	9679864391	La Curva	Duke	92
Roomm	5969619604	2109173935	Oslo	Schurz	78
Mydo	2037782141	5812272031	Carianos	Magdeline	9
Tagfeed	5852071722	6334044981	Bcharré	Golf Course	58
Innotype	6468913907	5448695591	New York City	Fieldstone	38
Edgepulse	1493557976	8442936956	Battambang	Dapin	22
Oozz	7754660416	9208263542	Partizan	Barnett	51
Yodoo	7947297629	8352390135	Uusikaupunki	Kennedy	95
Photojam	9704327830	2715839823	Grand Junction	Redwing	79
LiveZ	2299634443	2057315355	Zhenshan	Kipling	62
Voomm	4066749292	4354485495	Kafir Qala	Grim	17
Zoomdog	3747238025	8958822361	Pragen Selatan	Cascade	97
InnoZ	7132166573	8061783737	Jetis	Valley Edge	43
Dabshots	2236825079	7662021084	Bīr Zayt	Morrow	60
Jetwire	9979758114	4278305510	Nerchinsk	Cascade	55
Skimia	4275465911	5763270172	Zhongshangang	Reindahl	97
Wordware	9012406362	4011295575	Säter	Forest	30
Skyvu	4786810295	7935114974	Huangjiazhai	Stuart	99
Realmix	6666012832	9517065537	Irbit	Garrison	48
Oba	7016288917	1493702458	Warungbanten	Hovde	38
Twimbo	7102509470	3271088515	Kaliningrad	Thompson	45
Tagfeed	6979057111	3653264081	Kabukarudi	Washington	6
Pixope	3441831079	4177012136	Sayang Lauq	Sheridan	8
Jetwire	5797766978	6122254939	Uva	Manitowish	6
Trudoo	5204280536	3775296494	Tucson	Daystar	82
Vitz	9314055519	5127662947	Velyki Kopany	Havey	44
Bubblemix	6446551787	4196790706	Vicente Guerrero	Mcguire	71
Skipfire	3604668700	1036265926	Norrköping	Quincy	19
Brightbean	8515599755	5392610830	Valenciennes	Johnson	24
Shuffledrive	8092626722	3078920065	Mueang Nonthaburi	Delaware	11
Oyope	9997862226	9922461966	El Llano	Dryden	65
Skinder	8312223330	3258039267	Sebadelhe	Daystar	10
Skipfire	5974174605	5452265716	Morro Agudo	Swallow	82
Oyondu	3798450957	1791332495	Massenya	Morningstar	54
Gevee	3799916775	6802037513	Chalchuapa	Superior	29
Layo	5858069197	3459089391	Akademgorodok	North	27
Janyx	2834281151	1276399598	Lluchubamba	American	6
Digitube	1777152420	2798325839	Khotsimsk	Cherokee	43
Riffwire	6302254780	1582559999	Garawati	Moland	26
Eimbee	5836056255	6193049701	Ivoti	Tony	16
Aibox	3711225948	9556142459	Al Khawkhah	Utah	28
Jaxworks	9847275754	8035450125	Cordeiro	Butterfield	36
Katz	7586040125	8736380516	Samut Songkhram	Dawn	73
Geba	6272197197	5914881100	Kupino	Eliot	95
Chatterbridge	3049966784	6815718556	Sarov	Graedel	50
Abatz	7339762711	2817658468	Lampa	6th	10
Centizu	6119532204	8634591304	Xingxi	Pankratz	40
Meembee	8773456844	3745629849	Antipolo	Shoshone	76
Wordify	5595276000	6046418303	Cihambali	Sunfield	12
Zoozzy	3598899365	8987356024	Lebedinovka	Namekagon	15
Yambee	1619033798	9201370612	Sidi Slimane	Loomis	17
Abatz	5498797214	1178429409	Atlantis	Mallard	5
Flipstorm	5202362302	7307967346	Hongtu	Dahle	7
Yacero	3831090517	9493839699	Sidi Bousber	Jana	61
Tavu	9955600509	5596286269	Anyar	Sauthoff	99
Dabtype	8388446863	4956155986	Kalasin	Packers	32
Abata	1592809503	2569023198	Huolu	Hoard	7
Rhybox	1355758140	8716639130	Xinghua	Harbort	98
Kazu	5578917923	9055106639	Farkaždin	Logan	58
Buzzshare	7531252216	7914071139	Fifi	Trailsway	25
Viva	8605585298	9563713138	Huangwei	Eliot	92
Blogtags	3023293673	9578555013	Iwase	Rockefeller	84
Nlounge	1691612894	1797556490	Viesīte	Katie	73
Realmix	6369120317	2984230954	Chicoana	Elgar	77
Wordware	3263886049	1999771216	Mae Charim	Beilfuss	11
Yakijo	8652458038	8298079781	Kasese	Maple	50
Skiba	2803347484	1198910532	Qingtang	Schurz	30
Thoughtsphere	1812984773	6777878556	Malaga	Sundown	86
Devbug	2331308439	6104999720	Verkhozim	Division	69
Quatz	9778573275	3506436085	Masaya	Esch	6
Youbridge	1238437744	3817913214	Yanggu	Esch	34
Abatz	5903140057	8212326821	Kirkkonummi	Talmadge	66
Voonix	5464390551	6632343725	Américo Brasiliense	Larry	41
Skidoo	9254177745	9265263025	Rizal	Paget	44
Zazio	3987850549	1746646492	Mospyne	Reindahl	25
Yombu	8413593278	1704179592	Jiuxian	Raven	98
Camimbo	4549532764	8891348245	Era	Sutteridge	21
Fliptune	2632597350	8701505865	Uitiuhtuan	Artisan	31
Skidoo	5872542600	9879856181	Tuchola	Beilfuss	20
Myworks	5063580981	9612246119	Carepa	Dakota	15
Bubbletube	7201666783	2981923881	Shaoguan	Lighthouse Bay	78
Eabox	1412873461	1566098016	Xicheng	Fulton	74
Yambee	3299171105	3901839885	Wenqiao	Oneill	6
Flipopia	4143118240	1496211721	Hongqi	Anzinger	22
Einti	4834888059	3666036084	Madīnat Ḩamad	Shoshone	93
Yozio	5855610350	9038048558	Lawepakam	Tony	15
Leexo	5132091871	3157367548	Jinshan	Lotheville	29
Buzzdog	3849681464	4443624059	Lunenburg	Chinook	48
Realcube	6881823660	3313549788	Thị Trấn Mộc Châu	Muir	16
Skalith	1769623107	1091699150	Buôn Trấp	Sunnyside	7
Demivee	4891846424	4323191822	Tangzi	Maryland	100
Brainsphere	4671593782	2566496107	Primorsko	Elgar	54
Plambee	4447150816	6156939513	Galubakul	Sommers	52
Skimia	9093056330	5013071510	Zadawa	Sutteridge	17
Vinder	9784062717	1261735927	Los Andes	Waywood	46
Realcube	5257223476	3601449012	Guder Lao	Farwell	82
Tagtune	3365387716	8419893112	Asamboka	Macpherson	65
Yoveo	4623660981	6327570392	Vasilikón	Harbort	82
Skyvu	1814764914	6363589077	Zhentou	6th	40
DabZ	9309923844	5702345178	Leonidovo	Messerschmidt	61
Devpulse	6171728532	6072331364	Kajiki	Hermina	33
Quatz	4402358967	1314296749	Edissiya	Washington	50
Ntags	8185461105	3056141886	San Diego	Westridge	100
Skaboo	7989078320	7255435367	Plaisir	Miller	48
Topdrive	4552825704	4502709900	Woloara	Washington	45
Twimm	2279934016	7755838504	Labuan	Riverside	86
Flashpoint	9539121881	2644082029	Zhuangshi	Tennessee	54
Oba	3014361079	2928720933	Xarsingma	Vera	31
Nlounge	7301464939	9216107532	Rojas	Vermont	40
Eadel	6177424886	5228861566	Gaoling	Longview	16
Bluejam	6156634120	1407907086	Cungking	Colorado	76
Yakidoo	1249208495	6126319658	Sussex	Becker	10
Youspan	5701695730	8368166207	Čejkovice	Little Fleur	9
Brainverse	2192674520	2937566587	Lille	Granby	50
Podcat	8858271969	6155755592	Žďár nad Sázavou Druhy	Badeau	27
Gevee	2414748335	1547320986	Umeå	Ridgeview	59
Skimia	5874994150	9172931300	Alagoinhas	Troy	22
Devpulse	3156000610	2107650379	Bueng Samakkhi	Gulseth	15
Dabshots	8349792232	6255652370	Puncakwangi	Northland	69
Wikido	8704068415	6658093251	Motala	7th	97
Layo	1002256759	1595855970	Seiça	Cottonwood	9
Jabbertype	9305650718	7037196319	Rancaerang	Carey	83
Dazzlesphere	9928900413	4055365894	Ban Fang	Huxley	100
Centidel	4987136890	1435398825	Stykkishólmur	Spohn	72
Photobean	9646541002	1132685321	Ovalle	Laurel	26
Jatri	8744157988	2203085906	Bugarama	Lyons	81
Ailane	9907395052	9515224756	Huainan	Texas	28
Thoughtworks	7075612327	8398308079	Yingcheng	Kingsford	94
Mydeo	5729608193	7773585756	Székesfehérvár	North	23
Innotype	2721916010	5213611467	Skovorodino	School	18
Zoombox	1623496407	4279750756	Cavadas	Waxwing	96
Dynazzy	6244441931	6293539280	Wolowona	Hintze	47
Rhybox	6557541756	1926466688	Klenovyy	Texas	53
Shuffletag	4128144950	1776642590	Ipoh	Mcbride	38
Rhyloo	3488588264	4792856632	Jorok Dalam	Melvin	11
Devpoint	3178013668	5369407141	Tsubame	Chinook	91
Skipstorm	1654239672	8608978516	Sarandi	Shelley	77
Meemm	5464229905	2028292641	Kudus	Anniversary	69
Quatz	2915036772	4225116662	Ol’ginka	Anthes	73
Jayo	6476860605	1304413392	Fujinomiya	Melvin	49
Twinte	7135522814	2517216573	Bigoudine	Lakewood Gardens	79
Realfire	7858317058	6358466599	Topeka	Reinke	36
Voonyx	2018830595	7975928677	Sandefjord	Kedzie	22
Jaxbean	4902268468	5388979205	Mondokan	Fieldstone	61
Voonte	2083486526	9789849329	Edissiya	Fordem	81
Oyonder	8311426946	5256970843	Santa Valha	Shopko	18
Brainverse	6251703401	3218246720	Al Qardāḩah	David	34
Voomm	2112153673	9032754620	Zevenaar	Hazelcrest	61
Youopia	5821580942	3223263008	Krajan Joho	Dryden	59
Leexo	9259599846	8849073829	Lavradio	Trailsway	22
Skibox	5555318849	6771384561	Guang’an	Manley	8
Topiczoom	6183696293	1602814298	Banqiao	Lillian	12
Bubblemix	3293152802	9763913484	Brak	Crownhardt	5
Photospace	3118958088	8729641409	Taihe	Village Green	88
Babbleset	5355537266	8127595732	Ivouani	Duke	80
Edgeclub	2181136612	8014888475	Estombar	Magdeline	64
Kare	3746851529	9019755712	Tochio-honchō	Longview	16
Rhybox	5592206638	7062054869	Xinglin	Thackeray	72
Wordware	7186902225	3789967213	Pruchnik	Brentwood	39
Linkbridge	5043018751	5698504306	Świdnica	Merry	95
Geba	5765728093	3109966540	Cambé	Golf Course	77
Trilith	2046094067	9505044415	Los Mangos	Holy Cross	31
Layo	9489025134	6227530216	Shuanglong	Northwestern	22
Oyondu	5851505528	7687032541	Río Sereno	Summer Ridge	5
Gigashots	3577512152	8244566788	Bieto	Miller	97
Camido	5629395132	2625644892	João Pessoa	Harbort	42
Kwimbee	4689913379	2796837711	Sagopshi	Mandrake	89
Fatz	3788794438	2793574159	Óbidos	Haas	52
Riffpath	2831332787	4306848440	Paris 13	Fuller	62
Skiba	7035834762	4161810133	Fengli	Hazelcrest	20
Meembee	5661972249	6311147959	Novosineglazovskiy	Dakota	48
Centidel	4534267308	3448019993	Qiongshan	Manitowish	30
Meemm	1604559201	2065129852	Layo	Mallory	81
Tagfeed	7862017888	4857810420	Weixin	Goodland	51
Dabvine	6296618810	1242685815	Kotovo	Cordelia	100
Twitterwire	9597052862	3719029896	Panggungrejo	Meadow Vale	94
Mita	5373680804	9207699323	Campok	Hollow Ridge	74
Abatz	6124650450	5741580270	Alurbulu	Farwell	34
Jayo	8184910403	3415601374	Orikhiv	Rusk	66
Babbleopia	9293559645	5956563437	Pangkalan Kasai	Fairview	18
Skyvu	1815203552	1667814287	Baoping	Sachs	10
Zoovu	1608277062	1554461961	Jiworejo	Hauk	68
Yodo	4228883197	8414621568	Qingshui	Bowman	67
Muxo	4186810578	5048226780	Fujinomiya	Lighthouse Bay	55
Skippad	4403818833	7012453997	Pupiales	Bay	26
Eare	5803477982	5747292961	Guisguis	Bobwhite	24
Skyble	6036265976	1076642537	Babat	Bowman	66
Jabbersphere	5595942666	4638576326	Jiazhi	Manufacturers	90
Ooba	7347450059	9356600909	Marseille	Heffernan	58
Roomm	5437609147	5385201492	El Viejo	Main	86
Snaptags	2209355353	2621683332	Sasaguri	Orin	73
Browsecat	2958189697	5805248445	Jingdang	Dunning	82
Topicware	8743987935	2147837652	São Martinho de Árvore	Sommers	67
Zoomlounge	4733065420	7683768776	Arma	Merrick	92
Flashpoint	8527173469	4733242850	Pepayan	Lawn	43
Buzzbean	6296715469	2361552856	Madrid	Grasskamp	80
Fanoodle	3158077944	3796762026	Puno	Clarendon	72
Divanoodle	6343580905	2519102904	Bribir	Dennis	35
Oyondu	8132409194	6824411273	Buni Yadi	Artisan	26
Kwinu	8661702208	7388548037	Ivanec	8th	69
Jetwire	1006408374	6044367703	Sukošan	Messerschmidt	72
Rhycero	8503949937	3857860792	Tallahassee	New Castle	64
Jabbersphere	6118883183	3578080757	Wufeng	Muir	79
Vinder	2892536606	6361936970	Urjala	Oneill	24
Skivee	3825975567	3204178334	Nyköping	Mallory	77
Centizu	1997054817	2673892341	Riung	Dennis	84
Twitterlist	6046428941	2215040896	Ferreira do Zêzere	Saint Paul	13
Trudeo	3364759592	4513976928	Nantes	Holy Cross	55
Nlounge	3008369723	5129046633	Checun	Spohn	69
Skynoodle	4999177857	2929955531	Neftegorsk	Harbort	35
Trilith	7586037605	9187128118	Muesanaik	Derek	81
Vimbo	8701567315	8527044503	Muting	Sunbrook	34
Skivee	9252951468	1188539094	Villanueva	Fairfield	59
Babblestorm	1729400273	7491137850	Kauswagan	Superior	19
Skinix	2581251105	4053222293	Riyom	Hermina	88
Zooxo	1008294471	1507629240	Santa Catalina	Bonner	38
Ailane	8701846684	8749629078	Gaspra	Banding	43
Blogtags	7559617263	4846434602	Metsemotlhaba	Ludington	34
Zoonoodle	4288532979	7065013021	Halayhayin	Reindahl	22
LiveZ	5991554699	8464205000	Mawu	Commercial	57
Muxo	9123828612	2683199253	Rosso	Lighthouse Bay	48
Myworks	7013887707	1234437443	Bāglung	Bonner	6
Jayo	6348323960	4581734785	Paris 07	Hanson	75
Lajo	3118548267	6165223924	Lins	Sundown	23
Babbleopia	4478091030	5859214738	Kosino	Butterfield	46
Youopia	4363897207	1619093027	Apucarana	Maywood	35
Omba	3787303963	7162060159	Goranboy	Portage	38
Thoughtmix	7459779347	2522975381	Lāmerd	Hoffman	61
Browsecat	3816461919	4282042558	Sangpi	Logan	55
Yadel	6825376029	6109660917	Yangjia	Merrick	85
Wikivu	3222786068	7383347344	Larreynaga	Cordelia	20
Gabtype	3398208607	8313062822	Kedungbulu	Manufacturers	86
Mynte	8381456067	2966875938	Karangtengah Lor	South	53
Twitternation	9971261034	7891127239	Cieurih Satu	Farwell	40
Teklist	1452434024	1573946856	Lacabamba	Maple	6
Lazz	4573324212	4128930241	Krasnogorsk	West	14
Jabbersphere	2001388647	8637833306	Nerchinsk	Norway Maple	89
Quimba	4404726452	5255149377	Ljungby	Birchwood	83
Thoughtsphere	9368191083	1898459529	Waoundé	Forest Run	71
Digitube	8147362588	1423832755	Bianba	Crowley	22
Yodel	5533827015	5216071424	Puncaksempur	Mccormick	71
Agivu	9567236360	2052929139	Bungu	Anzinger	36
Photolist	2403163507	6622803085	Anto	Algoma	96
Voomm	3053740830	7524578481	Herne	Saint Paul	6
Browsetype	9337599933	2229993457	Shuangxing	Northview	23
Eazzy	9869211705	1385151922	Hongyan	Anthes	64
Linklinks	8861652928	1745324972	Tolomango	8th	45
Rooxo	1095499447	5882090008	Adh Dhayd	Golf View	26
Mudo	7505962709	5833691755	San Jose	Pleasure	94
Voonder	3426938296	3189554042	Chuoyuan	Hayes	12
Rhyzio	6543812703	5638887343	Batibati	Comanche	6
Eabox	8687391349	6781069790	Tianzhou	Blackbird	81
Flashspan	8159682327	8144886875	Natividade	Autumn Leaf	62
Topicware	6614662431	8105743888	Néa Karváli	Northridge	77
Riffpedia	7339653978	9138293358	Yosowilangun	4th	83
Plajo	7851783460	1509931845	Xiawuqi	Lakeland	73
Jabbercube	8526459227	9931791969	Pasireurih	Northland	47
Centizu	4479722757	7598612472	Keboireng	Acker	9
Fadeo	3735933482	6578076366	Kingisepp	Gerald	68
Brightdog	6871804688	2906081184	Aeteke	Kedzie	83
Twinte	7581143289	6098923049	Jiacun	Cardinal	93
Yata	6644916220	1619897487	Mullovka	Anhalt	94
Agivu	6919224172	6223134856	St. Catharines	Tony	10
Skivee	7392896025	3164511514	Umbulan	Steensland	95
Cogibox	9029415305	3294835320	Alanga	Debs	23
Skidoo	1835753308	9609903428	Oksa	Schurz	68
Lajo	4098504274	6494979768	Muurame	Cody	60
Topicware	4441937098	4242763115	Gunungbatu	Armistice	27
Layo	3179726146	5194053047	Göteborg	Magdeline	28
LiveZ	7766817000	2345199076	Nanchoc	Stone Corner	59
Dabshots	2619931406	7344599583	Dmitrov	Longview	31
Thoughtmix	5738829400	8509322506	San Luis	Dennis	68
Fatz	8176022858	9432231056	Vila Nova	Center	89
Browsebug	8605134392	9553375748	Marianowo	Anthes	61
Viva	3779254384	9428337763	‘Afīf	Duke	47
Zoonder	7088277795	2454863079	Kotanopan	Truax	8
Tazzy	7578024280	5385070005	Derjan	Calypso	71
Aibox	5478553897	4272779309	Pasirlaja	Lillian	51
Gabvine	4607243431	6148329147	Hannover	Mcbride	80
Bluejam	9738351525	5762408752	Yelabuga	Duke	6
Wordpedia	4835491700	2345328867	Sanjiang	Thompson	73
Avamm	6396011450	9361918400	Thị Trấn Na Hang	Jackson	15
Livefish	9855959523	6266975736	Altanbulag	Eastwood	37
Yozio	3797426488	8686514355	Xinshi	Brickson Park	93
Rhycero	8497554082	4254547450	Neob	Green	42
Feednation	7717374518	5133920329	Quinjalca	Wayridge	89
Realpoint	6935141590	5235803523	Jurangjero	Huxley	43
Divanoodle	4364003866	6728080669	Bengtsfors	Dapin	40
Tagchat	3687958626	6589973549	Gračec	Southridge	100
Topicware	1799679662	2128707504	Baykonyr	Grayhawk	71
Wordify	7776410270	8166053256	Galleh Manda	Hovde	47
Zazio	3922216887	8449166946	Lijia	Lerdahl	53
Livetube	6364811035	8528213551	Denov	Pond	38
Skyba	8956513466	7751199763	Miliangju	Banding	62
Mynte	4429867430	4047133300	Tōkamachi	Mayer	60
Buzzshare	2582024612	1667863543	Drawno	Atwood	43
Oloo	1569794945	5045383214	Telouet	Rutledge	79
Jaxspan	3212347220	8729109202	Poá	Packers	35
Pixoboo	1691294381	7312727147	Dem’yanovo	Clarendon	74
Photobug	6386193419	8009111685	Kokagax	Everett	73
Devify	3973037897	4726833157	Mozi	Tony	47
Aimbu	4477748787	9992312993	Manhete	Spenser	77
Tagpad	2277427420	3965673260	Mitaka-shi	American Ash	67
Geba	7622973477	8066645218	Pajannangger	Green Ridge	14
Roodel	8819203611	8722896612	Mendoza	Paget	51
Topicware	5236530953	8185534827	Wangkung	Northwestern	70
Tanoodle	5212030963	6467349171	Xunzhai	Melody	63
Demimbu	3827758986	6977355656	Yumbe	Lyons	68
Brightdog	6871370655	1078658011	Sipeng	Pierstorff	61
Abatz	7292034606	4665446793	Encontrados	Bobwhite	80
Photobug	4599918993	2304293200	Libiąż	Eastlawn	89
Twitternation	4129889072	2721663195	Narawayong	Vera	60
Flashspan	9588564788	2165365857	Alavus	Eastwood	29
Meembee	9602561809	8155253147	Quzhou	Gateway	84
Blogspan	7735325635	1629553640	Daugavpils	Graedel	13
Brightbean	3065170512	7867857126	Néa Sánta	Lakewood Gardens	94
Zoonder	9456177657	1242367865	Jiazhuang	Doe Crossing	75
Mydo	4725298926	6038057848	Gampengrejo	Melody	47
Brightdog	2005892523	9431891672	Fraga	Almo	81
Youopia	7756741273	3854597313	Guicheng	Spohn	89
Kimia	2675452344	5973314370	Boavista	Nova	91
Fivebridge	4558917497	8471132827	Västerås	Spenser	9
Wordware	7655710428	3508610512	Kokembang	Mariners Cove	89
Aivee	9938042504	3507621064	Stockholm	Truax	12
Kwideo	6918791898	5328895256	Ciudad Nueva	Bunting	19
Fadeo	3122829758	2876414162	Mantang	Scott	59
Wikivu	5362179702	4309790510	Río Limpio	Namekagon	93
Jayo	6187282739	3416004342	Oss	Sycamore	21
Topicblab	4478843092	2035805710	Asahi	Sycamore	64
Kanoodle	2972204051	1046721965	Nkongsamba	Everett	56
Edgeblab	3982510450	6853241708	Kolmården	Village Green	24
Livetube	9818861901	6207200021	Houba	Forest	48
Tagpad	1803906796	6542055004	Cikondang	Beilfuss	28
Rhynyx	5209164515	3765932758	Xinzhan	Sachtjen	49
Gabspot	9598574384	5656222381	Kasama	Welch	84
Geba	8626892251	9535098222	Santo Anastácio	Garrison	81
Realcube	5356901989	3569588581	Płock	Ramsey	61
Meevee	8488422907	4996589000	Stockholm	Mcguire	18
Devpoint	9527044025	2785759051	Glugur Krajan	Dennis	83
Jayo	5269941187	8082885005	Qishn	Old Shore	97
Wikizz	2887053270	9384748338	San Isidro	Ronald Regan	24
Edgeify	7046013245	8679844216	Sanyantang	Sullivan	66
Feednation	6333556093	2403875708	Kołaczyce	Carey	83
Thoughtsphere	6734810516	3204883127	Oitui	Nova	12
Flipbug	8691041655	3615310174	Świecie	Scofield	85
Bluejam	2602901163	4972143324	Fort Wayne	Park Meadow	23
Digitube	5777377596	7708639454	Airuk	Division	37
Skyba	9771141864	9976906471	Nässjö	Buena Vista	90
Gabtune	2271502564	1144253370	Uchkulan	Farmco	59
Eayo	7402264192	4214143858	El Espino	Lukken	50
Oodoo	7052370420	9009048763	Paupanda Bawah	Granby	36
Buzzdog	7135025109	1721830522	Zhongbao	Hoard	85
Realfire	3678218880	5544031549	Seia	Becker	52
Digitube	6245657288	5456284876	Kasulu	Pearson	59
Blognation	7826538705	4984210576	Khatsyezhyna	Cordelia	10
Topiczoom	3653148924	1145704089	Areni	Sunnyside	67
Trilith	6881065536	8624336351	Danja	Merry	65
Skaboo	3538037632	9082595004	Toulouse	Cody	99
Wikido	1875585766	6518640965	Helsingborg	Lillian	17
Yakijo	7758249229	9987962380	Carson City	Shopko	84
Vinder	7212809212	1322909905	Briceni	Monterey	31
Edgepulse	5948411085	4591782933	Sovetskaya	Granby	79
Avaveo	4952198609	4858163949	Évry	Oxford	53
Babblestorm	2254627075	3122978010	San Antonio	Farragut	33
Kazu	1701623086	4142275909	Färjestaden	Hoard	27
Plajo	8265764010	1605638066	Luksuhin	Homewood	6
Skimia	4786795693	6444455253	Melikkrajan	Rowland	74
Topiczoom	6188723000	1996214435	La Purisima	Mandrake	7
Centizu	7035709675	5221485306	Corujeira	Jana	74
Flipopia	2973165046	7342273316	A Yun Pa	Grover	97
Yambee	4379068253	3385049030	Potrero Grande	Eagle Crest	44
Vidoo	1504897006	7751977495	Ust’ye	Jenifer	24
Layo	4989920082	7528342960	Vladimir	Moulton	73
Ainyx	8623038181	4964116608	Luojiang	Sommers	79
\.


--
-- TOC entry 4859 (class 0 OID 24629)
-- Dependencies: 218
-- Data for Name: drug; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drug (id_drug, trade_name, maker, form, dose_mg, shelf_life_months, price) FROM stdin;
1	Vero-Netilmicin	ВЕРОФАРМ	solutio	25	24	150
2	Руцектам	Рузфарма	pulvis	1000	36	500
3	Grimipinem	Пребенд	pulvis	500	24	1000
4	Bicana	Натива	Tablet	150	24	1000
5	Tizanidine	Березовский фармацевтический завод	Tablet	2	36	1500
\.


--
-- TOC entry 4857 (class 0 OID 24616)
-- Dependencies: 216
-- Data for Name: drug_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drug_group (active_ingredient, drug_group) FROM stdin;
Netilmicil	Аминогликозиды
Цефтриаксон	Цефалоспорины
Имипенем	Карбапенемы
Bicalutamide	Антиандрогены
Tizanidine	Альфа-адреномиметики
\.


--
-- TOC entry 4862 (class 0 OID 24667)
-- Dependencies: 221
-- Data for Name: individual_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.individual_product (sni, id_drug, storage_location_id, production_date) FROM stdin;
78295123649448427628	5	54	2023-08-11
61288217465059389757	2	137	2024-03-12
84361692202022645182	3	151	2023-06-15
69629291089799950152	5	68	2022-12-19
20884147771558530910	1	85	2023-09-09
58411454309436351460	5	30	2021-08-30
33853588648582670680	3	76	2021-11-10
72318062889075940609	5	113	2021-07-23
80371891207526568213	2	185	2022-11-23
85150229785764758801	4	122	2022-05-23
64383257223195866584	2	151	2023-11-13
22892038608623505161	1	82	2022-03-08
55444038453681595761	3	117	2021-11-29
80210624613813834541	2	147	2021-08-10
67590860648653971069	4	46	2021-06-15
53732859292976170721	3	152	2024-04-01
99734390887542850190	5	2	2021-08-05
17748248144351530847	1	158	2021-09-10
97278537975918347490	3	159	2024-04-20
67225816422597059023	4	191	2022-02-06
94157265164942647424	5	110	2022-04-22
76773640057607483991	5	124	2021-11-19
67555695196564315184	3	128	2021-10-14
16458404933682222969	1	9	2022-01-06
40396475686229570570	4	135	2022-09-19
43397104012961943856	5	2	2024-01-15
30210969854815320794	4	4	2022-06-17
64248939259967146339	3	135	2022-09-29
87980005733275836028	4	169	2023-01-05
86270227647356375718	4	18	2024-03-18
53457708316418217284	3	41	2022-03-09
14491696538829222048	4	96	2023-07-24
30858558893162036981	4	12	2022-01-31
20930003284595239827	4	149	2024-02-10
10096814306539723218	4	131	2021-09-19
52144136685244096778	5	179	2023-03-06
40911401503537481715	5	187	2022-07-18
73993263425493966761	3	149	2021-11-08
87972437832029424715	1	88	2022-06-07
92445476606673435391	3	175	2023-08-08
41041673188477121011	5	173	2022-10-22
51671295042068911252	4	30	2023-08-06
37014737539286712322	5	35	2021-09-05
72231673744628073262	4	176	2024-03-10
93357159025741543143	2	148	2022-07-10
74692444783064258648	5	46	2023-09-08
65469325725174483524	3	199	2023-07-05
88938807373451575602	2	86	2021-07-08
85637528593536641053	2	126	2023-09-11
62917098713822522590	5	166	2023-02-16
56158873779171288859	5	50	2021-10-31
53318581835043444766	4	133	2024-03-19
93845046898765530397	1	53	2023-05-31
88071306135133127648	1	13	2022-07-18
23148656316784531470	4	32	2022-09-08
70337399616356841177	4	197	2023-03-06
24226997786603561933	1	120	2022-08-15
32571730293764816732	5	89	2024-03-02
37962685572861412718	3	191	2024-02-13
92847043397751835757	4	92	2022-05-18
74014915646446446237	1	33	2023-02-16
62327794269641146394	3	70	2022-07-05
53670055905443800210	4	64	2023-05-09
47857877064212970900	2	94	2022-03-10
31831037178707498509	3	95	2022-04-20
90552393783897205670	3	124	2022-03-01
70232799415912772922	1	181	2021-11-04
51336911574101221346	4	107	2022-08-17
84889524706058303158	3	175	2023-04-08
23192417804356932753	1	56	2021-09-02
51421140669847229877	5	98	2024-01-03
51868704048284867105	2	147	2021-10-28
84447087873022131094	1	140	2021-08-07
86469935247727963546	5	5	2021-07-19
14469393395447253940	2	163	2022-06-13
77097985251125485653	1	98	2021-05-26
54888527798617980825	1	17	2022-09-25
30567738135914900822	5	121	2023-02-15
71386977801977278856	3	117	2022-11-24
59316142986144458948	3	80	2023-05-21
91330632477027347577	4	63	2022-06-19
41645071154998215293	3	55	2023-08-16
60826801235938095758	4	137	2024-02-09
45287077749336924702	3	174	2024-01-13
97378765196257692756	2	66	2022-09-11
63635243376338179215	1	159	2024-03-19
72578045014947168701	1	197	2023-11-16
76559212229971190996	5	176	2021-10-06
61441913935133496751	1	146	2023-08-29
29228306453231617693	1	160	2022-07-05
26194750292482516160	2	68	2022-12-19
10711737528241898512	2	96	2021-10-05
43139577108923892374	1	170	2024-01-29
92918425626246551920	3	161	2022-09-10
18462243791941175835	1	15	2022-12-14
91936212628249319198	4	123	2022-06-28
63114474235869907352	1	123	2023-07-03
32382373089708898936	5	37	2021-07-16
79611395519071639114	3	35	2022-04-22
27718164825366543229	1	100	2024-03-26
14165713888069153427	1	68	2021-05-18
75547288359756237899	5	62	2021-06-05
39120259636911399781	3	138	2023-07-07
33460061198331211190	3	1	2021-09-12
36178710263771639523	3	148	2021-10-19
77137476487703077313	2	172	2022-03-20
96514406572854989169	5	124	2023-07-02
69062961819746893057	4	136	2024-01-24
88952164361732092874	2	172	2023-09-24
56995649583521229739	5	20	2023-08-27
97583430885302822791	5	78	2023-10-01
15251571791524932649	5	114	2022-01-17
49245682415743147124	1	24	2023-07-30
32433741576117907497	4	139	2021-11-21
92010353471373581759	5	33	2022-11-04
85936669912854681140	5	191	2024-01-17
81265500493319145922	3	142	2023-10-08
98957338768744073623	4	93	2023-03-06
36219951257419647606	1	58	2022-05-06
19099459723496574832	3	120	2021-07-13
33758108584287337514	4	174	2021-10-14
32793890496054971376	4	84	2022-02-21
23646211137435007673	3	160	2022-10-27
20231397648492595523	2	34	2022-09-14
18517647488768408659	2	112	2021-11-29
43233932829861211760	4	134	2022-07-16
40442184395227386989	1	157	2022-11-17
14731677072942578425	1	107	2022-11-06
30488308678012009703	4	194	2023-08-19
66753936564367206516	1	157	2023-01-10
20623396573285662019	4	91	2022-05-03
40688322954334474324	2	31	2022-10-17
48553642596277720448	3	115	2022-06-18
65044151027153132126	2	160	2023-07-27
84092600127751304328	5	152	2024-02-24
72349605526391775954	2	159	2021-10-18
36491418263862459581	4	49	2022-10-04
42492380432619485752	5	77	2024-03-31
87775919345916759595	3	162	2024-04-04
29039621524018240726	2	12	2022-11-15
60166170758098444097	2	85	2023-05-02
99225974978542594965	2	46	2022-04-18
69011843642422880968	2	93	2024-03-30
28141027204484393230	2	121	2022-07-22
22234181706738757571	3	18	2022-11-06
74491684184507951946	1	34	2024-01-06
85258203643408550153	3	189	2022-10-08
31921960985743998510	4	182	2023-02-14
77816382219167885176	1	60	2021-05-19
91670787426087231113	4	199	2023-04-17
46232094813507664375	3	31	2022-09-16
47669006973738215092	5	131	2024-03-26
19378179845341755090	3	78	2022-03-25
47934401402686846944	5	191	2024-04-22
38687566444319494112	3	192	2022-03-22
41361126235012281386	4	73	2024-01-21
28451902917457662782	2	191	2022-06-01
63564957351703343889	2	87	2021-11-03
55998297118366203331	4	40	2024-03-03
52149825622891715018	2	53	2021-05-23
18941088107578729720	3	171	2023-08-16
56484556696049099475	4	3	2023-07-02
34588791402124961386	1	129	2022-01-24
53679449067696978019	4	146	2021-07-17
67412196562757920453	2	73	2021-09-18
84375815928064524300	4	57	2024-02-28
89252272045867066235	2	61	2021-12-14
27958517482515095676	1	148	2021-10-21
54160927787356665384	3	94	2022-03-22
56540608521998035665	5	2	2021-05-30
27727526129962666596	3	68	2022-09-19
60396447617163900586	3	96	2022-01-05
53860788174667853754	5	36	2022-11-15
62966590341968820036	3	142	2021-06-01
63130195853366069521	3	191	2023-02-10
95677753047158215656	2	195	2022-02-24
37548485213899195764	5	83	2021-06-12
83540377737568652190	1	11	2023-06-28
78410617898451294949	1	140	2022-02-27
33681144932822253327	5	53	2022-10-15
31977638364914444502	5	27	2022-06-23
58830923352962490618	4	113	2021-06-26
16336819706505790475	3	161	2022-02-23
10135128987491017103	3	17	2023-08-04
88539901704978671135	4	159	2023-05-27
63055306546518872115	3	119	2021-05-23
94390926069698352092	5	165	2022-06-28
73967896606806657695	4	144	2023-08-02
47950360371712046008	1	62	2021-10-22
41958662262959206418	5	142	2022-07-28
89772588022016654317	3	90	2024-03-07
10514538819907592993	2	137	2022-05-19
71624869511093231506	4	9	2021-08-21
55779818977231673070	2	168	2022-06-28
77474617833916658183	4	144	2024-04-03
12252346471779746918	1	154	2022-08-22
85015729193763069986	2	138	2021-06-20
95596615269763926231	1	17	2022-07-28
94787877713532070198	4	190	2021-12-17
41151860566325037803	3	9	2021-06-10
89645461293314324858	1	63	2023-03-25
34332530732663577659	3	174	2024-02-21
64237700497577753393	4	76	2022-04-22
90325240386579354808	4	187	2021-12-06
30416198747676517374	4	168	2022-09-16
23177226684235701032	3	144	2022-01-15
80047767369556984421	2	102	2021-08-22
27521017872258255249	5	93	2023-09-16
88973708334372339554	3	109	2023-10-16
84721167387404464594	3	164	2021-06-24
57984463234993102582	5	82	2023-12-28
34180684953864436524	1	22	2023-03-06
94743376893583396515	2	83	2022-02-10
68299676113858722608	3	124	2022-12-02
65781718541841626219	5	156	2021-09-02
73584639555895868354	4	165	2023-03-10
25273081245265994838	5	27	2023-09-06
25880144944698547099	2	34	2021-09-07
89769817202496245873	1	118	2022-04-08
38488756603863804949	4	97	2022-11-03
19860512119465615991	5	86	2021-10-11
17365087676808887863	3	133	2024-01-24
64876833167331592651	1	48	2021-12-28
56865534312487182119	3	160	2021-08-19
30596231562375490584	2	160	2023-07-14
69513148135515298447	3	94	2021-11-11
17486442326179656206	2	95	2022-03-01
11059750445687760104	4	17	2024-01-11
85079055155986338673	5	23	2023-11-04
67056312462259907572	1	21	2021-11-28
13986645341162693329	4	197	2022-01-17
31562414011284863038	2	123	2023-10-29
41076878909759193745	2	107	2021-11-15
12973682342114243257	1	125	2024-03-29
24088759431018416166	5	7	2023-08-17
40012500289563600327	1	135	2022-10-02
25959904088314511281	5	23	2023-01-08
32799915799482797337	5	52	2021-12-12
35721587913118699265	2	130	2023-03-30
23681423291623055040	1	61	2024-03-09
34694762517467460894	4	102	2023-05-15
71168070091156383846	2	193	2023-11-24
88610611276906187013	5	42	2023-12-05
83162319302735443941	4	167	2024-02-07
15823667734762482687	3	126	2021-07-02
48640769707348962941	1	121	2024-02-02
86598805616323905470	3	16	2021-12-04
18710573659046259590	1	136	2022-11-26
89722476281549698167	1	144	2021-07-26
91173128821007623893	2	164	2022-08-12
54214821738831613941	4	41	2022-06-25
88443752035541235211	5	34	2021-09-08
43559808599678357523	3	197	2023-07-05
40214492657478338801	2	106	2024-02-25
26910719202632091441	5	15	2022-10-09
35432341696521292206	1	23	2022-10-07
29556797041663672439	5	73	2023-05-04
30735668459268000641	4	107	2023-08-03
39126085609981482204	3	142	2021-08-19
52539744145614512655	2	131	2024-03-15
69345241791823909452	4	46	2023-01-09
46184991984627001057	4	42	2021-12-07
40041869965745022311	5	193	2023-06-30
70821132732797868639	1	90	2023-12-24
63754479352406494449	2	43	2023-03-08
99835224847032354814	5	96	2023-08-26
88449708101282864153	2	110	2023-05-21
34997087476807211693	4	152	2023-05-06
65259386861738732364	5	150	2024-02-29
95630165983329002464	5	146	2023-08-22
94919140185789780694	4	38	2023-12-22
82955456451008424391	1	17	2023-09-25
34112008471162708112	5	90	2023-07-28
25442887598725500534	5	41	2024-02-03
67298313369776447989	5	162	2021-05-16
87484620608562731602	2	18	2022-09-10
60439999961729053377	4	156	2022-11-30
34049180545435961020	4	103	2022-06-05
13924269495907954904	5	77	2022-06-14
13177253343887977438	5	108	2022-06-26
78644765591077027566	4	156	2023-04-14
39795528105719107781	3	30	2022-11-02
39379706921267128651	1	82	2024-03-29
96215277428841817299	5	177	2023-10-13
44641338865398948901	3	191	2023-08-24
26020074243404585960	4	52	2022-04-14
83487075014973884232	1	182	2021-11-21
33632180577829064888	4	119	2021-09-04
60960347056015270140	1	133	2022-03-07
80147489233614473486	3	88	2021-10-02
25749002876731594750	2	166	2024-04-11
97880972228624811067	3	154	2024-04-21
51677121159101224615	2	54	2023-12-05
41727140964585156802	5	49	2023-01-23
50774211461468549827	3	153	2022-02-14
13634721718818138629	2	73	2023-12-31
86725797972796500748	1	116	2021-09-02
79819433677661156139	2	142	2022-06-16
59643124558026680672	3	171	2024-01-22
86161141635709794637	2	106	2022-05-21
15038822595632667567	3	32	2022-08-26
45597103291841204824	4	51	2024-03-21
17745404169904103791	5	105	2023-12-15
26696663976515330445	5	125	2023-03-23
38042019494182156388	1	57	2022-08-29
44783552039974768465	5	168	2023-04-10
51975296368065992324	2	54	2022-08-17
80039019349908775897	3	60	2022-04-20
98815378095923231543	1	48	2023-11-05
36295028892425624085	1	146	2022-05-05
63267973749014759931	2	134	2022-10-21
52935292359091133447	3	94	2022-09-19
13866033041612262091	3	185	2023-02-18
90085226288559087034	4	105	2021-07-08
55282901198528790945	1	11	2024-03-05
93468290596911693499	5	150	2021-06-01
38260060854667029907	2	110	2021-06-26
92795178638583473286	4	23	2023-03-26
86353035192516804367	5	42	2022-03-24
24456768269373211538	3	102	2021-08-06
17936039996991099130	5	12	2022-10-19
85819265339235065774	3	141	2021-07-16
29439275288313177478	3	20	2021-11-27
70911466351284283799	1	28	2021-07-15
77219210877569547718	5	20	2024-02-24
51197289149463687961	4	15	2022-01-16
54296548357078299205	4	5	2021-05-15
33876846168656157908	1	136	2022-03-25
34584467329618509701	4	131	2022-07-14
93144821531472408170	1	18	2021-10-27
43725367512245089489	4	8	2023-11-18
36612505354971203633	2	119	2021-10-17
50186035627339490939	5	130	2023-03-25
56777472332479931838	3	82	2022-10-21
11532363684811701872	3	111	2023-01-14
85197112233635080111	2	167	2024-04-03
13612643249518865987	5	125	2023-03-18
55798796554215358144	1	89	2023-11-25
62681531165746274633	5	4	2021-05-24
66857947997066363396	1	126	2021-11-05
55681441943878067374	1	20	2024-01-18
18860805682521108165	3	73	2021-08-16
33990430344787479902	5	124	2022-05-23
54052053737008247401	2	43	2022-01-19
16348245906628271240	3	64	2022-06-28
20667867432721931817	2	47	2023-03-07
61962127292716777027	4	90	2022-06-19
53456501801938021193	5	141	2021-12-16
74829481909127337519	3	165	2024-04-19
99933523812701013034	5	112	2022-12-27
62414615734526667019	1	144	2021-07-09
30114263371952152218	2	154	2023-06-26
66976193545323203689	4	19	2023-11-02
98186721447431275769	1	7	2022-02-22
54322036567127566521	2	96	2022-04-21
48211437443256730075	2	34	2022-11-12
25141060828754254343	5	14	2022-03-17
86079831746553198735	4	10	2022-04-30
85952772669967730032	5	56	2022-07-07
55376183994519225701	3	69	2021-07-05
22945593749218966801	2	26	2023-02-04
87171242176586325717	3	102	2022-05-04
90241930777496728469	5	68	2022-11-16
63487945971433992337	2	116	2024-04-01
75997943345083089169	5	98	2022-12-25
18726821242863954251	1	148	2021-12-08
58890028951084406056	2	68	2021-06-24
38524611732797555454	4	60	2022-11-07
86624867717425358344	4	44	2022-02-25
97751229367115427459	4	100	2022-09-07
96792317934162724798	2	68	2023-12-17
77985759185643582819	1	145	2023-09-08
23321365194665818611	3	146	2023-12-18
18740971739866728630	5	27	2023-10-15
10045407233135594944	3	122	2022-02-11
73654639532919055173	5	50	2021-06-14
57665944324437181812	1	54	2024-03-25
78846636066478569515	2	106	2022-07-01
75794388286821981977	4	41	2023-04-23
24850863658036212079	5	85	2023-02-03
15734493656039086978	5	30	2022-06-20
93247502065838057371	3	85	2024-04-20
58920116875589819432	3	68	2022-06-11
91317060494974343875	4	44	2024-04-22
53520891789664747933	1	113	2022-10-19
61510643183025082623	1	11	2023-01-04
51775049432651657998	5	99	2022-12-09
27226380365203348459	5	24	2022-08-08
50334082181994958043	1	33	2022-06-15
55192309713172340294	4	32	2023-12-30
18496570384663817695	4	72	2021-09-10
22614877928074155835	2	76	2021-07-20
23588667427533967508	2	12	2022-09-30
81385995827712260776	4	193	2023-02-14
70536906899072437800	3	109	2022-01-07
65749255434029575173	2	117	2023-10-15
10211633441569337700	2	130	2023-02-26
22616961761829531810	1	113	2023-05-31
30312722176842934048	5	98	2023-04-03
52255857944516158559	4	125	2024-02-12
39446346593805650871	1	71	2023-09-01
80499463734232199538	1	46	2024-04-05
23473103276576697192	3	33	2022-01-07
33099332103082057699	5	47	2022-08-29
14322212236263099066	5	103	2021-12-28
95463711648997486150	5	72	2023-07-25
80160645978126198546	5	54	2023-06-08
97113466622391642870	3	199	2022-11-11
69110480314697804152	5	43	2023-09-16
60622481271883904344	1	151	2023-11-02
24990437609995617386	4	186	2022-04-16
90716396634257478813	3	133	2023-10-30
15567650243257121112	3	167	2021-08-02
29737799568567046298	3	102	2023-05-12
20751188711932361415	2	90	2023-05-07
42559344631183989283	5	103	2021-09-26
25055189885275699628	1	170	2021-12-11
81031472361286543396	4	28	2021-06-25
76350336209313362731	5	19	2023-04-12
21543321471573972494	2	39	2024-03-30
68854074027802942653	4	170	2022-01-28
25188437489421938784	5	188	2022-08-03
36399180663868080058	4	177	2022-03-27
41066629734225214151	3	116	2021-06-07
21015621332979613015	3	198	2022-02-05
64640269964764122132	3	143	2021-09-06
39954208669236153473	2	145	2021-11-13
20595516497381388526	1	80	2022-04-09
69742351955546993861	3	94	2023-01-04
39642012155318217010	1	3	2024-01-25
34540442659147994721	3	179	2021-12-04
24092962485377324512	3	103	2023-05-22
55813026276212424547	5	162	2022-03-03
25558240292149770658	5	74	2023-08-21
78859602932854557406	1	112	2023-08-02
98199156848572447121	4	111	2022-07-20
81815985435122529776	2	87	2022-04-26
34333792075828682509	1	141	2024-02-20
21321925836845362802	1	185	2022-08-03
20818732968504737016	1	130	2023-07-31
74932249043524208476	1	143	2022-05-21
51774430118722306259	5	162	2022-10-21
83387201503868147006	3	71	2022-12-31
33390936075173621854	1	77	2022-04-23
88167752428408925490	3	105	2022-07-05
33225204266928729730	2	68	2023-02-13
87385598776022041633	5	154	2022-02-23
36227356088978741179	5	150	2023-09-05
48363852836363279644	4	130	2022-12-20
23066362073039076012	2	192	2022-07-29
99354381272648112919	2	5	2022-05-03
87851322706581037452	4	94	2022-10-15
85191287331856137499	4	154	2022-06-24
47154166871049449060	3	74	2022-04-22
59610917321802174691	3	126	2023-10-07
28575886814478196213	5	72	2021-11-25
37115602568478836894	2	173	2023-05-30
15676144992779831681	5	82	2022-04-18
61583827898211520231	2	150	2022-10-21
33794251075416668648	2	149	2024-01-06
29367783742831269836	2	189	2022-05-07
57493003973957315338	1	88	2022-10-17
95543944755164415045	3	171	2023-04-16
91226500982819543682	2	148	2023-06-12
78175058749046257851	5	108	2023-07-30
47284640541326188910	4	140	2022-02-07
95928563828948501356	3	82	2021-11-24
83925220505677821907	3	157	2021-12-29
72719738296343141158	1	119	2021-10-12
55235929147364143672	1	65	2022-04-09
89273144108501676575	2	28	2024-01-17
89114625516339899461	2	64	2021-11-04
23172045667563332142	4	158	2023-04-24
90937035916958981729	5	23	2021-07-10
62170487068456343371	4	128	2022-06-22
24558145911557021214	2	119	2023-05-05
54853912202188399126	1	181	2023-03-05
65664120415465900741	4	149	2022-08-09
56071328277492339313	4	198	2022-07-14
92337089822534345749	2	108	2021-07-13
57020331052115067429	4	13	2022-01-13
13944084313593963046	1	188	2022-03-19
23931265793293092286	2	72	2023-08-21
47244981642258550490	2	97	2023-07-20
27742324515542854622	5	54	2022-04-18
30393129982483096279	5	5	2023-12-21
33424311174928362089	3	106	2022-01-12
72086529801707562674	1	120	2022-04-08
91455338574555213863	5	189	2022-02-06
37258887629418683223	5	126	2023-11-28
13176485646226379386	2	87	2023-12-16
50471597781198280281	5	42	2024-04-10
55284185408882429552	3	190	2024-03-10
28868531826471534318	1	75	2021-12-19
18742606353238632303	5	129	2023-03-02
62675645746909038456	1	105	2024-03-16
84749147387982032902	3	106	2021-11-16
99570881482269007309	4	59	2022-06-08
20855033826121827285	4	77	2022-06-09
86926651731729947372	1	5	2023-01-05
22719532218882460621	2	123	2021-06-07
26542843535586146586	4	133	2023-04-18
18783570351111816235	5	186	2023-07-17
53247171664483343583	1	39	2024-03-10
33070288159998782286	2	39	2023-05-08
31015630756776522708	4	33	2022-11-13
81843310412806885816	3	174	2022-02-12
48845215242746304437	1	95	2022-09-22
43487153998662785637	4	138	2024-04-02
96178055381648536808	3	17	2021-07-22
40170179087792050140	2	172	2022-10-08
61960018523569943903	5	13	2024-02-01
46025993212053860497	1	154	2022-02-12
98535392361485570618	5	18	2021-08-18
48944704339707740558	1	194	2022-08-08
82468043197251757581	4	32	2022-06-11
38265899027435475190	5	186	2023-02-08
50895687733984331792	2	35	2023-06-17
19970840926932406344	4	132	2022-05-21
90718540869059685165	4	32	2022-06-13
39091904468351514766	2	80	2023-01-14
48680266269485395577	5	21	2023-10-07
51916374121906395514	1	40	2021-09-24
93864639022636641635	5	186	2024-01-09
30190895335358568368	4	133	2023-08-11
75924225488733532854	5	28	2022-02-19
16523158406032492368	2	187	2022-07-14
11831828804417071599	3	133	2023-01-31
63217569644232322448	4	61	2024-01-11
61480961515264888594	2	170	2023-01-31
67887241947922016652	1	120	2021-09-15
76427572674431510198	5	17	2023-03-31
98860505461834943856	4	102	2024-01-04
26775370898248980506	4	190	2022-08-30
87556326428601378673	4	82	2024-04-30
92870263099005686414	1	31	2022-10-03
22176533265211627526	5	59	2023-01-31
76736647774645853068	5	163	2022-01-26
17899909794402890507	4	7	2022-06-01
41257807996294939649	5	124	2022-04-21
53161016545444028997	4	34	2022-05-08
76883871441947935915	1	184	2022-08-27
56620448565586878024	3	58	2023-02-13
16643529652624629948	5	181	2023-03-10
56193888102503282667	4	129	2021-05-31
66339624809506184375	4	92	2023-07-29
56327774224604844090	2	159	2021-12-21
18484050243566070510	3	96	2022-06-06
67150245031535295849	5	4	2022-06-21
83569105069648796907	4	130	2021-12-23
42586052344383761534	1	160	2021-12-08
95623008192285863659	1	174	2021-05-24
62713624305819953482	3	62	2022-05-10
22390221005492152137	3	169	2022-08-03
69249159555405926110	3	159	2021-11-23
13761810465442515500	2	19	2021-08-06
92890183807864743362	4	157	2021-07-26
63318148705247619331	2	163	2023-12-23
17277665512391882359	3	162	2022-06-04
45642330261916473572	1	195	2021-07-05
32074564449554436954	2	32	2021-07-18
55882387017341918419	2	140	2022-05-16
12554021476984399633	2	153	2023-04-10
35599214784778644293	2	59	2022-09-30
42625902144992392402	5	75	2024-05-01
24571826221536859581	3	146	2021-05-26
12913530048217085972	1	91	2022-06-01
86196784276873053987	4	8	2021-12-21
68046140921323685709	1	3	2022-06-30
27436935826114137773	1	122	2023-11-24
78718576097233328874	1	103	2021-09-11
32142082437644486422	1	95	2023-09-10
28772288626246337495	4	57	2022-04-23
64993432666694017723	3	61	2023-01-21
81174482711528267335	1	4	2023-02-11
27856814612768105534	5	149	2024-01-21
41745289234058423698	4	175	2023-06-06
12311043925392987051	2	85	2023-09-15
99530641057402513361	4	102	2023-09-05
58870826369478099072	2	34	2022-10-15
53880140182359604754	2	57	2024-03-29
93033702621356902864	1	97	2023-03-22
66087290861022866312	2	188	2021-05-31
11623069661457659198	4	121	2022-09-20
25577276898169117781	1	196	2024-03-20
67726851997067219285	3	5	2022-06-01
12769413153618087949	5	182	2023-08-23
54771144759559984985	2	181	2023-10-28
25724985596276419661	5	99	2022-04-23
62219220031349007906	1	155	2022-04-07
51599107743931156515	2	122	2021-10-06
88366137466594627190	3	93	2022-09-06
20585741963507254518	1	67	2022-04-02
17376387293809570116	4	68	2022-04-24
33789025635611739369	4	114	2022-08-12
45958187375435776665	5	156	2022-06-09
20325268914293049445	1	124	2024-04-17
72746319265964229955	3	160	2022-07-25
27737114212195001404	2	90	2021-06-29
70136861421834829458	5	170	2023-12-11
17850341859627238240	5	183	2021-12-05
71733434577339075284	4	140	2023-10-19
96974209576267415776	5	70	2022-12-18
31873105147297480276	3	52	2021-08-03
17050750008272488471	2	192	2023-05-07
11585414957946502702	2	13	2024-01-03
74713783924015505807	5	94	2022-10-13
87062231386809369226	4	64	2023-12-12
52136652207501359159	5	162	2021-11-14
15315021373188381781	3	165	2023-02-10
31827851777489997287	1	20	2022-06-15
96355495053848219932	2	142	2023-01-05
28978926281267349216	4	183	2021-09-18
98739817921483963559	3	137	2021-08-04
14458249231385032521	3	26	2021-11-22
17476725772691835019	4	64	2021-10-08
98189429145053112743	1	8	2022-04-25
29691261268081054524	1	3	2023-12-08
25111544329202792598	2	103	2021-11-23
12031012301295175321	1	199	2022-03-06
36796235202582938061	1	20	2023-10-02
93037327223799333690	5	81	2021-08-08
31257256312632843564	1	30	2023-11-01
61379737486417381992	2	150	2022-08-09
82625983295125196765	4	197	2022-03-08
51315965859681160670	2	177	2022-08-27
60820991902817551587	2	182	2021-07-26
85362326586199305203	5	47	2023-03-31
69689646077493159257	4	150	2023-03-03
89462231264839654521	5	23	2022-11-21
95710260076293654514	2	45	2022-08-16
98098208251118613877	3	159	2022-08-11
79780953608736385750	5	52	2023-05-17
27318932712846168316	4	111	2023-05-28
24647753798871801146	1	127	2021-12-07
57459670243966247067	4	142	2022-02-28
73273350846993724602	4	44	2023-01-05
34173060524067428361	4	148	2022-05-01
63959415321227754155	1	59	2023-01-16
92898023995112292982	1	119	2021-07-15
11164135158875378877	3	152	2024-02-08
41763693362744908322	4	126	2023-05-27
36844460914488192951	5	12	2022-06-03
84834616165585058335	1	103	2022-11-08
56865634552962814468	5	129	2021-05-17
29464497117845374841	3	24	2023-08-24
28171224519216975034	4	137	2022-02-06
29154150449644006157	4	158	2024-03-10
13473926603963593970	5	13	2024-01-06
10486696915226888421	2	191	2024-05-03
37387594949014753799	5	124	2024-04-06
54913891568523994230	2	93	2023-10-07
71132751782128004984	1	36	2022-08-28
45440691247159419365	2	60	2024-04-18
99623973656349551490	3	93	2022-02-11
48338734344906773805	3	49	2023-09-29
54263171131981232551	5	96	2023-03-18
96581521491446260371	2	195	2023-03-15
83468103279749028337	4	125	2022-05-31
48336803715176899770	4	15	2022-08-02
61450737549327491813	1	38	2022-03-11
59979910798973525441	4	103	2021-08-11
35026523489036698547	1	138	2023-11-03
83020728951614966602	3	43	2022-01-20
25152798408211053298	2	43	2021-05-30
24644769833745693942	4	9	2024-02-28
57677477481609268194	4	137	2022-01-13
62287161774993616383	5	151	2023-01-05
78074214114546306429	1	47	2024-02-11
79416135925428732632	3	182	2023-11-19
57914235909558940837	2	170	2023-11-19
30918446844728905014	2	88	2022-11-01
61564593592961135239	5	14	2021-09-10
68551697617066804015	2	4	2024-04-15
54168629108614291212	2	116	2022-03-05
65361607716618046632	5	180	2022-09-14
20730166132051267908	2	67	2024-03-16
47621865883838881269	4	61	2023-02-24
33081499745441949992	5	139	2022-10-13
77078629354295829645	4	51	2021-11-10
66366789489377062432	5	8	2024-02-24
98836405046873418628	4	24	2024-04-19
60816766392744215231	3	103	2022-12-11
56850708844037393633	4	81	2021-08-02
41218005672065732346	5	179	2022-10-26
78947644033318398684	2	67	2022-06-14
34819715149905450630	5	53	2022-01-10
86564578713416920457	2	77	2021-08-26
47669389765992590267	5	30	2024-04-13
30928364596955953885	1	58	2024-03-24
19541503796492822607	3	56	2023-03-19
85881052956688407770	4	147	2021-07-19
32475967154227864953	1	119	2022-10-20
66673440546087679287	3	11	2023-03-30
48645348321901411430	1	65	2021-09-04
99932149734368738652	3	13	2023-09-12
16236445997082997661	2	137	2021-09-02
24966088728236203698	1	33	2021-08-06
14945615294786872374	1	111	2023-05-19
49571211847267764248	1	25	2023-01-24
89671887964388059617	1	186	2022-09-17
40943074336635990316	3	183	2022-02-21
18531878712316738774	2	171	2023-05-22
27910430002856366854	5	2	2023-09-06
61576179918952818324	4	56	2023-01-22
22880571288372507081	5	56	2023-11-19
99230094404931961220	4	43	2021-09-26
69930878379468474817	1	56	2024-01-14
77025754956848063563	4	40	2024-03-08
46179722412725764800	1	153	2023-07-20
21966639857194426663	2	177	2023-02-09
47988868522089233958	3	102	2023-03-15
17229048585235339187	5	59	2022-01-05
80485334789359694965	1	189	2023-02-12
71154827454723811284	3	189	2024-04-10
15552052176787784142	2	136	2021-07-03
47139052081135137536	4	10	2023-04-23
90519029815209595812	4	65	2023-06-30
73699312512185163588	4	102	2023-06-12
12673709112068252577	2	89	2023-02-11
11595830089457469836	2	80	2021-06-25
65364078114706051991	1	171	2022-01-31
46832416383587275090	2	41	2021-11-19
20888095645125187717	5	151	2023-05-17
35646500027531988639	3	143	2023-01-05
65069563712736288560	3	138	2023-04-02
71593838152071186640	1	96	2022-07-26
13842623059882646328	4	91	2023-11-29
97985291932516060336	4	89	2021-08-20
67969949136357604240	1	116	2021-06-03
47552904598572196782	3	6	2021-05-19
23377279997798187422	2	88	2023-06-01
25594200029347360019	5	193	2021-12-16
56379453711848265330	3	70	2023-11-01
83913776681723538381	1	73	2022-09-01
96116969014456641358	4	160	2021-08-18
73655269044738134165	1	190	2023-03-01
97356653678111380457	5	39	2022-12-05
73147792278202008556	3	173	2021-10-02
32495317132389948354	3	6	2023-10-24
60693868698508837323	2	82	2022-07-12
76240209832154363987	4	49	2022-12-21
22392403533149307108	2	42	2022-10-18
84368567259323289945	1	178	2022-08-21
87829837097071319254	4	110	2024-01-13
27964055357071705935	5	196	2022-08-22
95896543808677541620	2	78	2021-08-08
76680065365011093792	2	112	2024-02-06
76124818594476576597	2	145	2021-07-08
96336673226123237159	1	167	2022-08-28
80929275058133473673	5	184	2022-06-20
94566847137164678292	5	163	2023-12-05
29969718629164455800	4	47	2024-04-15
58353973901366685465	2	174	2023-10-25
12287939396715360695	3	71	2024-02-26
61387131267546502979	1	177	2024-03-23
10023366964581734414	1	142	2023-03-12
18679456144437326816	4	58	2022-02-06
51736865463378035113	4	21	2023-02-06
42257143349107270821	5	25	2023-07-06
11465572081597378618	4	134	2023-04-10
95552632211866422428	5	86	2021-06-25
35353476538066120609	1	6	2023-01-08
12275829066512595855	3	188	2023-03-14
43724544334458506382	5	43	2021-10-26
19898867106763321129	5	107	2024-04-08
55125341328772673429	1	63	2021-11-08
11779664296606608817	2	123	2022-03-09
19894463646234837626	4	31	2022-10-12
61397225548377446882	5	56	2023-04-02
76872485132392893697	2	87	2022-05-28
64855583893664525544	4	21	2023-05-17
88587244859254400360	5	38	2021-06-20
36333353583667324510	2	130	2023-12-25
22959942987865022736	4	101	2023-09-10
68565067285125362900	4	163	2022-01-02
74194498352915837913	1	169	2023-12-25
57747898511276596044	1	43	2024-03-05
16261410945348479707	2	114	2022-12-13
98056508951847578976	3	137	2023-12-07
17628031431296861168	4	30	2021-07-11
58741149622098125403	2	11	2023-08-08
88935522191826493831	2	17	2024-03-27
67722356099377236886	4	23	2023-05-16
85646432287998552467	2	116	2023-07-28
75281963437008168182	4	46	2023-05-02
19341827859552287077	2	41	2023-04-13
67860984366873634386	1	191	2023-05-29
77625360812659555511	4	180	2022-08-12
57750053283425946203	5	46	2023-09-30
61439836074205608754	2	166	2024-02-17
30153294134409841517	4	112	2024-03-22
45931252521034665610	5	59	2023-10-24
35451394287059400802	3	146	2023-06-06
14338701475296878255	5	125	2023-03-08
56460547453657184232	1	106	2022-10-29
61491831737611100068	2	110	2021-07-05
16943518087203732123	3	177	2023-09-25
24061588211058432087	5	48	2023-11-06
68038707117109090954	4	158	2022-10-20
80011333335377828828	3	158	2023-10-04
55419263831832868752	4	25	2022-01-29
49138901694495504987	4	132	2021-06-28
14748737135919834496	1	95	2023-02-23
33186373681093204963	5	88	2021-07-27
13611140237622841325	1	35	2023-01-11
56075516547603414488	1	35	2023-03-14
34868572962192131603	1	88	2023-02-11
57131642044225316906	1	124	2023-11-01
75786435043337559195	1	95	2023-04-16
73243287253062562329	1	184	2023-06-12
11771633623971917029	3	165	2021-07-08
42113784983704144293	1	39	2022-07-24
20864442139713765364	2	119	2021-08-19
19199513058903320321	3	61	2021-10-04
56944356592043445793	3	182	2023-11-12
55486840914591229190	4	55	2023-05-01
81071189798588183243	5	122	2022-04-24
96882767347078466296	5	107	2023-05-10
46583964354461231370	4	42	2021-11-21
31076033227964459653	5	18	2023-11-06
94187872111686367770	4	67	2022-04-19
15635501996606550595	2	128	2022-11-19
24397618678316609883	4	170	2021-09-06
95196288316066948301	2	137	2024-04-04
92486696544569514783	3	176	2023-10-20
28971283114167963671	1	187	2022-08-22
97826793674518225347	5	58	2021-09-24
18896353405023658254	5	123	2023-08-13
24384606327588875165	4	79	2023-05-12
66949761903963275973	5	117	2021-10-04
79925564946229953142	1	153	2022-07-27
74991937857548858201	4	24	2022-08-02
11649070217776178330	2	80	2023-04-17
34492476002967259689	4	23	2021-11-06
44427082256148101527	5	25	2024-02-08
48170522523914419408	1	23	2023-04-22
30054255547279971967	5	182	2021-07-29
45831254313871235818	2	43	2022-05-10
69366845351994936236	1	60	2022-06-24
73096932922214236934	2	51	2023-01-19
99491276346648348244	1	191	2023-01-26
96899063527756425624	2	80	2023-01-06
17344860548772651284	3	95	2021-06-08
97588794388382346793	3	153	2023-09-20
71964015257955764944	3	172	2022-12-20
11636984977219219610	1	170	2022-06-30
50851753004184219794	1	21	2023-02-05
73197623634137735612	5	12	2021-07-15
26541667119184974848	3	175	2021-07-05
32794497861761913104	1	97	2022-07-23
14585091052674798014	5	102	2023-09-22
60979543751871031094	4	175	2023-11-29
78671291195212537915	4	156	2023-12-27
71287622352761631136	2	11	2024-04-21
49680845548773451247	3	133	2023-08-18
80119712716672143157	3	164	2023-04-21
19072788679446538474	2	54	2024-04-26
99334356901629768806	4	89	2022-09-28
21859323594064035181	5	75	2022-12-31
63433450698759039688	5	199	2022-09-26
40460818927676709711	2	42	2022-05-01
65040836056551763592	3	55	2022-09-08
48484672639304520071	5	90	2021-05-16
77254265876624667092	1	20	2023-06-22
78926935083804601900	5	116	2021-12-05
75312975038216971878	1	42	2022-07-21
47813799339862490416	2	128	2023-09-27
59419186449743833707	5	3	2021-06-06
84946890907325014283	4	17	2023-02-16
44189951376551417380	3	27	2022-02-15
31246394945317593617	5	198	2021-08-21
92993565622772482488	4	110	2023-07-30
32831958656809437623	2	151	2023-02-20
11522348303908474268	1	158	2022-01-05
35943460983037020831	5	8	2021-06-22
95468550058953933089	5	61	2022-09-26
32565715675859161520	2	66	2021-09-08
67247235095759302624	2	100	2023-08-23
16690234405295333342	2	162	2023-01-04
99634903944341107593	3	26	2021-09-26
31396518758055534822	5	84	2023-04-09
85426354794965630096	2	79	2022-08-19
66077015429694459659	4	40	2022-08-23
33838149396506049784	5	94	2022-03-10
85250927214087323781	1	155	2022-12-18
57639167581686051765	1	128	2021-12-18
54174095402517123368	3	9	2022-08-19
76419381962739409875	1	121	2022-04-06
45776165327146000419	4	171	2023-01-06
31594170464847952796	5	74	2021-09-30
18972587827661884242	4	123	2022-12-25
24732949682389980248	4	35	2022-02-03
80940930062623371020	1	129	2023-09-11
88572947651812551034	1	137	2021-05-12
45086238057555570284	2	49	2023-05-18
48174564531245838017	2	185	2021-09-28
42377491691795208770	2	78	2023-09-09
38544549459436140276	1	198	2022-10-11
70137577074066828498	1	144	2021-08-20
98479853294702833343	5	28	2022-07-17
51514350686375872197	2	139	2022-04-24
41172869201054650272	5	172	2022-02-10
41864051205827677943	1	10	2024-03-20
60253522559726664883	4	147	2022-03-18
13671893734544743798	1	42	2023-01-06
95014325837894735435	3	57	2024-03-08
47011144353383878632	1	144	2024-03-16
49863814391339193228	5	198	2022-09-10
28243989934533604070	5	155	2023-05-09
50751879501243252090	1	102	2022-06-05
35440225239511018625	4	139	2023-11-03
15539015001073059407	1	66	2022-01-13
38826015998258481213	1	197	2022-10-29
81681630964108147122	1	106	2021-06-23
95622667837294618729	1	109	2021-07-29
52249238853299609237	2	111	2023-10-31
55091574257563579473	5	149	2024-01-28
17530437084077769573	2	73	2024-03-04
62351082909151025518	1	53	2023-01-20
25458244469522127252	4	127	2022-08-27
58185897677045036140	5	149	2022-10-31
19964094547272161983	5	170	2022-07-10
61461576659401267071	2	160	2024-02-22
19029483603132158697	1	33	2022-06-26
80290801619071150355	1	169	2023-08-02
28041673265766389928	3	150	2024-01-14
33940500284279878099	4	57	2022-08-15
55675207242287483761	5	112	2024-02-29
67348024157853405892	1	54	2022-02-15
44769531313869616378	4	69	2022-06-23
26559810674053121802	2	3	2021-07-19
13315368403164191591	5	37	2022-11-07
88999505193908041669	3	27	2024-04-03
18273520666553167931	2	33	2022-11-14
94675106649025456295	3	65	2023-08-26
82955853507036373915	2	142	2022-12-29
67846264599262884277	3	67	2021-12-26
96827831947731523568	4	187	2023-06-07
70154172802241516175	3	81	2021-05-27
70265265952422474453	2	101	2021-05-14
75691709666436093055	5	116	2022-06-06
89758332622114210285	5	163	2024-04-29
55151277871195376701	3	38	2022-04-09
70845080692027488056	1	199	2021-12-17
21150979202641520635	5	7	2023-01-13
57322948488288299907	2	149	2023-07-16
54272383824955803117	3	114	2023-03-13
56711662401627807216	1	173	2021-12-02
78772973953426844633	2	43	2024-04-29
40060036984691576447	3	144	2023-10-27
81728964677948701352	2	190	2023-12-25
21959856176168631147	3	44	2024-02-27
40032185139117744426	1	9	2021-06-27
56838426196723188780	2	163	2021-08-30
91289355249817665228	2	129	2022-01-06
31842827255763906615	2	107	2022-03-30
39431707441052035183	3	181	2023-08-27
65547482823687792467	1	93	2022-09-19
21036861959661348962	1	116	2023-12-12
23479262575183161116	5	4	2021-05-28
71392988525005867993	1	140	2023-05-08
37213472618392549507	5	147	2022-05-10
95270313889384793688	3	129	2023-09-19
85879011716916876184	5	195	2023-07-29
78152395107556744988	2	36	2022-02-04
72833024754597366529	4	59	2023-05-13
68398601518231381947	3	104	2022-12-16
61353927291378171390	2	31	2022-06-25
35440675864754368212	4	20	2022-06-07
99421713222217430139	1	44	2023-04-17
70817997661225668087	5	61	2023-08-03
29581223918178767046	1	191	2022-08-06
32159273686488233087	3	147	2023-03-05
88255419807823901707	3	99	2023-08-05
81482614946499181730	3	22	2023-03-01
29545384564221343516	1	127	2022-11-18
49115675076045298247	1	43	2022-12-17
40984870044779192255	3	77	2021-09-24
69339139162413797895	4	54	2023-02-13
58685653537046872592	4	30	2022-08-02
45921740137132303339	3	5	2021-09-21
43011950098713534592	3	22	2022-01-11
42620705048144646512	2	28	2023-08-24
44787002517589621748	2	27	2022-03-27
23963483847331305514	1	43	2022-10-23
40322957386054306616	4	60	2022-03-01
98315400837642415481	2	4	2021-09-16
53088392915084176716	2	192	2024-03-03
26620404391116123784	3	102	2023-10-17
44876412637756013139	1	56	2023-10-09
61755212297054168285	2	68	2021-12-25
97070947815253164890	1	114	2021-07-10
47582828714644185051	3	153	2023-01-16
50251336888698505288	3	193	2024-01-21
41774008103986988401	2	179	2024-04-16
51758616991493181195	3	196	2021-10-08
62126734761191836975	3	90	2022-04-16
57773012621432914214	5	125	2021-08-25
18235564071792949510	2	108	2024-03-31
\.


--
-- TOC entry 4865 (class 0 OID 24691)
-- Dependencies: 224
-- Data for Name: moving_drugs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.moving_drugs (id_transaction, sending_or_receiving, cost, phone) FROM stdin;
2	f	719.8	5984618071
3	t	852.9	7392896025
4	t	346.6	1153001202
5	t	1247.6	2051102156
6	t	968.3	1153001202
7	f	1764.1	1881828915
8	f	611.1	5878054287
9	t	1914.6	3966042655
10	f	1822.2	7003071776
11	t	1643	3711225948
12	t	1808.3	3849681464
13	f	1106.7	9855873978
14	t	1940.6	7998772866
15	f	270.1	7123479238
16	f	1017.5	8679328968
17	f	1046.1	7755271322
18	f	1440.1	3761578356
19	t	1107.1	5464390551
20	t	239.8	2912574114
21	f	754	4989920082
22	t	1524.1	8515599755
23	f	1582.4	7985181928
24	t	817.6	6644916220
25	f	478	6557541756
26	t	1964.2	4478843092
27	t	1571.1	2173428025
28	t	213.3	5738829400
29	f	297.2	2524459888
30	f	403.3	6018328128
31	t	1336.2	9697615163
32	t	1976.1	9847275754
33	f	170.8	4715845548
34	t	701.3	3272092860
35	f	681.3	5114326039
36	f	1099.5	8497554082
37	t	1742.6	4607243431
38	t	1166.6	4001061718
39	f	458.6	2065831392
40	f	902.7	5316272178
41	f	1936.3	4275465911
42	t	188.6	2035274447
43	f	457.2	4999177857
44	t	1052.5	5471414477
45	t	304	6887870539
46	f	716.4	3829811387
47	f	1037.7	8279065070
48	t	1682.6	3849681464
49	f	1626.2	1002256759
50	f	340.9	3823222198
51	f	229.7	2702019005
52	f	561.1	5373680804
53	f	1503.3	8701846684
54	f	1256.1	2912574114
55	t	1613.2	1881828915
56	f	942	5729608193
57	t	1578.6	1654239672
58	t	696.3	4759911649
59	f	1807.1	6348323960
60	f	947.7	1787483748
61	f	672.6	8605585298
62	t	1379.3	2171461594
63	t	245.2	2508939627
64	f	1613.2	7325060405
65	t	1362.2	7194721987
66	f	168.3	2663778343
67	f	1127.4	8362949904
68	t	353.4	5132091871
69	f	1887.3	3395078230
70	t	1609.5	4055598984
71	t	985.5	6465727058
72	f	702.7	5533827015
73	t	1726.1	3299171105
74	f	1908	5146618149
75	f	1693.4	2997281760
76	f	1614.3	6156634120
77	t	175.8	4447150816
78	t	1584.6	4253714311
79	t	191.1	9442573713
80	f	667.7	5487037120
81	t	273.3	2331308439
82	f	1923.4	7826538705
83	f	431	7766817000
84	f	1620.7	3354518194
85	t	1229.2	1506835403
86	t	460.1	4549532764
87	t	830.6	7135522814
88	f	785.3	1835753308
89	t	1736.7	2766081492
90	f	1558.5	6871370655
91	f	836.3	5489281298
92	f	545.5	6183696293
93	f	1710.3	4498799887
94	f	302.5	2065831392
95	f	1521.9	7626290912
96	t	732.9	1412380656
97	f	956.5	5063580981
98	f	1658.3	6224502787
99	t	1386.3	2033466765
100	f	1126.1	9855873978
101	t	509.2	6979057111
102	t	950.3	9093056330
103	t	1453.4	7135522814
104	t	1740.9	8524575010
105	f	1602.6	3538037632
106	f	1686.3	9861259540
107	f	217.4	1293857352
108	t	1697.2	2091971880
109	t	1197.2	6705034171
110	f	1028.9	7081341825
111	t	1286.8	9759917737
112	f	1673.2	7595697164
113	t	668.1	1548319062
114	f	984	5832721078
115	t	1213.3	4759911649
116	f	895.6	2524459888
117	t	288.7	1803906796
118	f	1649.4	2112153673
119	t	1382	7782563369
120	t	1091.4	7194721987
121	f	881.5	4842539207
122	f	1484.7	8311426946
123	t	1857	7041887962
124	f	1011.9	7546103729
125	f	206.1	5204280536
126	t	947.6	2115780478
127	t	1405.1	8264942143
128	f	250	5388279770
129	f	420.4	9888874483
130	t	953.5	9657561975
131	t	207.8	3488632870
132	t	1587.8	8392547695
133	t	1243.8	1184479470
134	t	1567.8	1691294381
135	t	1633.3	6124650450
136	t	911.1	6465727058
137	f	1257.5	4967853399
138	t	831.4	7632072068
139	t	184.6	8313929418
140	t	1693.4	7167773850
141	f	1739.2	9759917737
142	f	222	5696108773
143	t	1906	9861259540
144	f	1270.7	3059896184
145	f	1349.6	4879435059
146	f	1436.9	4912886783
147	t	1731.2	2602901163
148	f	1055.5	7581143289
149	f	1256.6	8796695924
150	t	1391.1	3565096565
151	f	277.5	5712760451
152	f	742.1	8605585298
153	t	233.8	9598574384
154	f	1499.9	2303202363
155	f	1001.6	8679328968
156	t	927.4	5437609147
157	f	858.7	9976759129
158	t	1731.7	7325060405
159	t	165.2	4996155014
160	f	1708.5	9663210635
161	f	995.4	7758249229
162	t	912	2303202363
163	t	669.8	8677317827
164	f	1352.8	8687391349
165	t	1764.5	3087697056
166	t	505.4	2171461594
167	f	537.6	5237090601
168	t	1552.4	7325060405
169	t	1207	5429838004
170	f	995.9	4447150816
171	f	1463.1	6614662431
172	t	773.8	2181136612
173	f	1844.7	1412873461
174	f	1002.3	2033466765
175	t	1901.8	1351717023
176	f	221.2	2121655989
177	t	1975.5	5257223476
178	f	1405.3	6226822934
179	t	1214.8	6369120317
180	f	298.3	3179726146
181	f	1300.3	7578024280
182	f	971.5	6475369506
183	t	300.2	9858543757
184	f	791.8	5874994150
185	f	1905.2	2973165046
186	t	1486.1	3372245964
187	f	520.3	1064243997
188	f	1726.4	3405817585
189	f	791.8	1591078548
190	f	1970.7	1048878401
191	t	805.7	5615461261
192	t	515.4	2432484958
193	f	1633.5	8242924095
194	f	885.6	1426354434
195	f	321.7	6715013072
196	f	1739.7	1701623086
197	t	1118.4	6215023273
198	t	936.1	4786810295
199	t	1172.2	4664585386
200	t	659.9	1997054817
201	f	1546.7	7321945032
202	t	1207.1	4689913379
203	t	406.1	5948411085
204	t	254.6	4624440499
205	f	1968.1	9585476083
206	f	1990.7	4326115859
207	t	636.3	2091598842
208	f	1551.1	9627309179
209	f	703.8	8159682327
210	t	1986	7292034606
211	t	964.6	4842539207
212	t	573.1	6623600244
213	t	1968.6	2303202363
214	t	1648.5	6296715469
215	t	744.7	5777377596
216	f	532.8	8896198555
217	f	699.1	9588564788
218	t	1917.5	2271502564
219	t	1301.6	4378156486
220	f	786.3	6852347850
221	f	359.9	6177424886
222	f	338	8756852162
223	t	1334.4	3354518194
224	f	839.1	1958904112
225	f	1372.8	1742261492
226	t	1074	6887870539
227	t	236	9093056330
228	t	481.7	6392333977
229	t	977.2	7632072068
230	t	1159.1	6479558729
231	f	790.7	6177424886
232	f	530	3395078230
233	f	1645.1	1008294471
234	t	1485	9912101362
235	t	834.9	6468442219
236	f	779.3	9017015731
237	f	1408.1	7301464939
238	f	1382	8047700762
239	f	1535.9	5629265405
240	f	1581.9	8392547695
241	f	333.6	7847925794
242	f	1397.2	4558917497
243	t	1515.6	3299171105
244	f	1334	8755696811
245	f	431.6	8251948425
246	f	855.6	6016791371
247	t	261.1	8554448156
248	f	771.3	6127281382
249	f	773.3	9532532910
250	t	344.1	2173428025
251	t	1954.2	2277153786
252	t	428.1	1793585454
253	f	746.6	4228447330
254	t	949.9	8528523141
255	t	444	8518436268
256	t	1253.9	6072134284
257	t	985.7	2632597350
258	t	1027.4	1881828915
259	f	203.7	6226822934
260	t	971.9	3741091296
261	f	1570.3	1843411992
262	f	840.3	3205152340
263	t	334.3	9726441515
264	t	1764.3	1296271635
265	f	1112.5	2381991111
266	f	1080.2	6792927951
267	t	875.3	7948329043
268	f	1265.5	7494746282
269	t	617.5	1654239672
270	f	1684.6	9726441515
271	f	466	8393497806
272	t	381	9979758114
273	t	483.7	9489025134
274	t	1292.8	8599024637
275	t	1595.9	9293559645
276	t	1277	7826538705
277	t	1683.2	2121655989
278	t	733.5	1412380656
279	f	1058.7	9527044025
280	f	370.8	2331308439
281	f	1622.9	1997054817
282	f	1831.4	2903450966
283	t	1277.4	4902268468
284	t	188.9	3653148924
285	t	1627.5	4555283751
286	f	539.3	9635964411
287	t	797.2	6224502787
288	f	493.7	6177424886
289	t	1575.5	9132587691
290	f	1937.3	7252160245
291	t	1014.6	7586037605
292	f	851.9	7301464939
293	t	341	5132091871
294	t	1123.2	8279065070
295	t	1510.7	3604668700
296	t	591.1	8623038181
297	t	1031.6	4253714311
298	f	1607.9	3167187682
299	t	1473.7	6693914590
300	f	1501.2	8528523141
301	t	492.3	9384847458
302	t	628.2	8028799314
303	t	760.1	6792927951
304	t	810.9	5595942666
305	f	1677.8	9058732220
306	t	201	5082864125
307	f	632.7	7766817000
308	t	759.5	1635886052
309	f	334	6796440183
310	t	597.2	2915036772
311	f	246.6	9357771800
312	f	953.5	4996155014
313	f	452.1	9314817760
314	t	321.2	7947297629
315	t	1647.8	3789406474
316	t	1685.3	6983748006
317	f	706.7	7735325635
318	t	1568.5	3426938296
319	f	338.2	3313720402
320	t	837	6393063971
321	f	552.8	1539997927
322	f	1809.9	4513157764
323	f	1791.6	4699329895
324	t	1533.9	3673282719
325	f	394.4	7016398061
326	f	180.7	6614662431
327	f	1368.2	7711970177
328	f	1666.9	8251948425
329	t	875.8	6531406206
330	f	998	9912101362
331	f	593.6	4017253363
332	f	1952.4	8313929418
333	t	343.6	3744888124
334	f	1386.9	1608277062
335	t	1007.6	6226822934
336	t	881.1	7194721987
337	f	635.1	2903450966
338	f	846.2	4391359539
339	t	475.8	4467741934
340	f	1919.2	1493557976
341	t	1004	8896198555
342	f	869.3	9888874483
343	t	597.1	4715845548
344	t	1299.8	8568944355
345	t	1975.6	7075612327
346	f	250.1	6369120317
347	f	725.9	1426354434
348	t	1580.8	4879435059
349	f	1665.9	2721916010
350	f	1144.5	6603851277
351	f	762.3	6392333977
352	f	625.9	2892536606
353	t	1354.7	5797766978
354	f	1247.6	6852347850
355	t	529.4	6983748006
356	t	837.7	6302254780
357	f	1225.6	7325060405
358	f	1116.6	9646541002
359	t	595.1	1504897006
360	f	1881.4	8455010924
361	t	1135.6	9205871972
362	t	1218.1	3141486705
363	t	1681.5	7024891668
364	f	525	8099130557
365	t	203	6217965684
366	t	1969.4	8796695924
367	t	1291.2	4441937098
368	f	872.4	4782417631
369	t	603.7	3565096565
370	t	884.3	7989078320
371	f	1960.1	6393528795
372	t	716.1	1777152420
373	t	965.2	3935962387
374	f	1392.9	8187342429
375	t	218.9	3825975567
376	f	264.5	8272115711
377	t	605.8	2142724920
378	f	583.5	9252951468
379	t	1220.9	9927388263
380	t	358.6	3656086500
381	f	1650.3	9017015731
382	t	1788.4	8185461105
383	f	1188	1325003074
384	t	215.4	3656086500
385	f	1156.8	5696108773
386	t	983.6	3797426488
387	t	393	2562273037
388	t	357	6244441931
389	t	1794.5	9394325509
390	t	644.3	8756852162
391	t	1145.2	5269941187
392	f	1718.2	6215023273
393	f	176.7	9309923844
394	f	980.6	6735137353
395	t	1648.4	5874994150
396	f	1828.4	3302277821
397	t	1860.9	2414748335
398	t	1911.7	4478843092
399	f	362.2	7826538705
400	t	589.4	7595697164
401	t	1131.9	7578225780
402	t	160.3	1293857352
403	t	1300.8	9938042504
404	t	1592.9	9738351525
405	t	1753.5	2803347484
406	t	855.5	8349792232
407	f	1097.3	9857109140
408	t	1427.1	2948186963
409	t	974.5	8973420735
410	t	607.6	4259471318
411	f	1921.7	3398208607
412	f	1190.8	6132557719
413	f	346.6	6917628112
414	t	457.9	1777152420
415	f	428.2	9855959523
416	t	310.9	9771141864
417	f	1358.2	6269773219
418	t	1691.5	2014320617
419	f	1851.8	3212347220
420	t	658.2	9588564788
421	f	1685.4	4126358950
422	f	1785.6	7347950415
423	t	813.1	4836532563
424	f	1450.1	5237090601
425	t	1705.9	1881828915
426	t	407.3	7847925794
427	f	356	1002256759
428	f	1619.8	3162642058
429	t	839.8	6018328128
430	t	769.1	5884877924
431	f	587.3	2766081492
432	f	907	6369120317
433	t	1405.5	6364811035
434	f	998.9	8187342429
435	f	488.8	8708802927
436	t	1632.7	2663778343
437	t	1016.8	2236825079
438	t	1310.2	1803906796
439	t	962	4155318408
440	f	1972.2	9132587691
441	f	789.1	9938042504
442	t	499.1	3445463912
443	f	1884	6825376029
444	f	1838.5	9163231348
445	t	1601.4	2072740077
446	t	1531.2	3023293673
447	t	1832.4	8846489209
448	t	721.4	6894091393
449	f	1011.6	1452434024
450	f	1783.5	1095499447
451	t	1355.5	4945930063
452	f	1407.9	9029415305
453	t	1518.3	3819860925
454	t	1921.2	2122893316
455	f	468.8	1287227331
456	t	1767.8	5935674963
457	t	1594.8	2432484958
458	f	1058.9	6127281382
459	f	690.4	9058732220
460	t	1597.2	4809129559
461	t	1723.3	7586040125
462	t	858.1	2975010767
463	f	1037.4	4599918993
464	t	1689.9	6244441931
465	f	1654.4	7347950415
466	f	1413	7135025109
467	f	1822.3	3935962387
468	t	1370.5	2973203837
469	t	990.6	1058647231
470	f	1197.3	5206427198
471	t	1173.3	5533827015
472	f	840.7	4749874298
473	t	697.4	8091601034
474	t	1170.3	6951325051
475	t	503.4	2112153673
476	t	709.8	7851783460
477	f	155.6	9121328061
478	t	1169.2	3356492405
479	t	1163	1539997927
480	f	454.1	7392896025
481	f	1808.6	1489832301
482	t	258.6	1096077674
483	f	350.2	1376507299
484	f	1853.8	2207738698
485	t	1071	9545790261
486	t	1973.3	7592843949
487	t	913	7998772866
488	t	172.6	8626892251
489	f	1060.7	6825376029
490	t	1074.3	8203071562
491	t	601.1	6226822934
492	t	1735.9	2615796239
493	f	1777.5	8973420735
494	f	258.4	8132409194
495	t	1836.9	8392547695
496	f	510.7	8701567315
497	f	798.3	9907395052
498	t	1904.3	2546627927
499	f	1729.7	2403163507
500	t	1084.8	8627428280
501	t	1453.3	6175170524
502	f	544.3	6125634524
503	t	476.9	4403818833
504	f	488.5	6792927951
505	f	501.1	6199819562
506	f	817.7	4363897207
507	f	1303.8	6479558729
508	t	1572.1	5018286620
509	t	1054.7	7046013245
510	f	1641	2371665065
511	f	1406.6	9384847458
512	f	1801.6	9858543757
513	f	1891.9	1426354434
514	f	1961.3	2903450966
515	t	1737.7	3973037897
516	t	981.5	4689913379
517	f	1295.6	3816461919
518	t	1743.9	7766817000
519	t	1863.1	9243374221
520	t	683.7	7081341825
521	f	1280.8	2774978643
522	t	160.5	1815203552
523	f	178.2	4599918993
524	f	257	2948186963
525	t	1018.2	8187342429
526	f	1527	9121328061
527	f	1067.7	8524575010
528	f	391.3	6369120317
529	f	966.7	1141746423
530	f	736.2	9597052862
531	t	303.8	7116167385
532	t	786.9	5472964736
533	t	1472	8708802927
534	t	286.8	7862017888
535	t	1121.1	9759917737
536	t	1086.8	7123479238
537	t	1930.1	7622973477
538	t	1352.6	6269773219
539	t	667.2	8272115711
540	t	890.6	5874994150
541	t	1174	7546103729
542	f	1344.7	6296618810
543	f	1088.9	4055598984
544	t	438.7	9243374221
545	f	323.4	1351717023
546	f	1973.4	6894091393
547	t	1404.9	3987850549
548	t	1321.5	1881828915
549	f	1263.2	9697615163
550	t	873.4	5974174605
551	t	1796.9	3398208607
552	t	1869.2	8171509903
553	t	1294.2	7046013245
554	t	497.3	3887496952
555	t	283.1	6343580905
556	f	1433.8	6333556093
557	t	1517.2	2836429294
558	t	511.3	4733065420
559	t	958.1	4483238746
560	f	1653.4	6479558729
561	t	1948.8	2972204051
562	t	1029.8	7851783460
563	f	1214.8	2689446499
564	f	1741.2	3799916775
565	f	528.5	5188564307
566	t	1151.6	3426938296
567	f	222.8	9907395052
568	f	368.9	3118958088
569	t	186.7	4644373989
570	t	535.8	2142724920
571	t	1799.2	5578917923
572	t	1057.4	1178471934
573	f	1046.1	2149855120
574	f	1080.7	1635886052
575	f	1410.5	2001388647
576	f	1556.8	4055598984
577	t	1762.8	1355758140
578	f	381.7	5257223476
579	f	940.3	8381456067
580	t	1358.7	2632597350
581	f	1553.9	3445463912
582	f	152	6296715469
583	t	1618	2581251105
584	f	250.3	1654239672
585	t	1666.4	1002256759
586	t	1815.8	8091601034
587	t	918.6	4671593782
588	t	280.8	8313929418
589	t	1249.9	4211963455
590	t	1840.3	7578024280
591	f	1539.8	4664585386
592	f	1334.8	6138303024
593	t	1787.2	4792680958
594	t	1585.1	1539997927
595	t	921.8	3049966784
596	f	807.9	8137478414
597	f	1092.3	6036265976
598	t	183.6	8744157988
599	f	1138.6	5935674963
600	f	1492.5	8743987935
601	f	618.3	3779254384
602	t	1996.7	7339762711
603	t	1573	8141888449
604	f	479.3	1997054817
605	t	971.8	8896198555
606	f	1764.6	5414574014
607	t	1187.8	8867461509
608	f	842.9	4228447330
609	f	1940.2	3065170512
610	t	1816.5	1287227331
611	t	1347.7	8599024637
612	f	338	6468913907
613	f	1723.1	6043903531
614	t	184.6	8599024637
615	f	1084.1	6894091393
616	t	1815.1	4392426762
617	t	1886.8	3065170512
618	f	611.2	5388279770
619	f	1783	8497554082
620	t	1763	2173428025
621	f	427.9	2122893316
622	f	990.6	4634231738
623	t	1399	2766081492
624	f	1424.1	7143676191
625	f	1277.9	5777377596
626	f	1378.3	2051102156
627	f	1309.7	2163957487
628	t	486	7339762711
629	t	1280.6	3935962387
630	f	1582.3	6175170524
631	f	871.5	3411842898
632	f	514.6	3176848862
633	t	1458.5	5988133843
634	f	1285.8	4715845548
635	f	1866.6	9935973089
636	f	1002.2	3869516952
637	f	1012.1	1958904112
638	t	377.1	3014961615
639	f	872.3	1856365400
640	f	1728.2	9602658540
641	f	1104.1	3169358676
642	f	150.2	3029884805
643	f	1586.4	6296715469
644	f	512.8	7186902225
645	t	744.9	8858271969
646	t	577.1	7088277795
647	t	1940	5421970405
648	t	888.7	9411831388
649	t	1632.3	9327853627
650	t	1267.9	4634231738
651	t	734.4	8896198555
652	t	438.9	4841610573
653	t	1543.2	9778573275
654	t	921.9	8187342429
655	t	505.3	7212809212
656	f	201.7	4094130268
657	t	397.8	3302277821
658	t	303.4	8148360947
659	f	190.5	2997864998
660	f	361.4	7252160245
661	t	1852	2148153631
662	f	1901.1	5236530953
663	t	1694.4	3598899365
664	f	1508.7	5464390551
665	t	370.8	6918791898
666	f	1449.4	1691612894
667	t	1939.7	3571810321
668	t	392	2892536606
669	t	1952.5	5204280536
670	t	792.2	2681859903
671	f	630.4	7559617263
672	f	1831	7214206476
673	t	1713.2	8554448156
674	f	714.5	6918791898
675	t	1142.6	4585098037
676	t	1716.2	8383852162
677	f	1831.8	9818861901
678	f	1581	8312223330
679	f	307.1	9205871972
680	f	1707.6	9598574384
681	f	1768.7	2277153786
682	t	1519.7	8819203611
683	f	1975.7	9769891513
684	f	1777.6	3356007255
685	f	1546.5	9525497064
686	t	507.9	3014361079
687	f	1288.7	7392896025
688	t	575.2	4143118240
689	t	1142.5	8021827429
690	f	168.2	1376507299
691	t	166.2	3922216887
692	t	1345.3	1701623086
693	f	946.5	8649085981
694	t	1537.2	1245073538
695	t	957.8	7851783460
696	f	194.7	8728082934
697	t	1527.4	4479722757
698	f	641.9	3789406474
699	f	1969	3405817585
700	f	676.1	8171509903
701	f	1353.9	3356492405
702	t	1267.6	7622973477
703	f	692.3	9127133845
704	t	1398.4	2538436210
705	t	1331.4	3565096565
706	t	426.9	8701567315
707	f	827.8	6715013072
708	f	397.9	6363859318
709	t	930.8	5464390551
710	t	1895.3	6211926423
711	f	1665	5858762874
712	f	306.7	8826085344
713	f	1997.1	8159682327
714	t	1995	5114820666
715	t	534.5	8728082934
716	f	982	1793585454
717	f	1218.8	3687958626
718	f	322.2	7013887707
719	t	665.1	9031689869
720	t	745.8	7586037605
721	f	1844.1	2071039882
722	t	668.5	4017253363
723	f	1781.6	4404164486
724	f	893.3	8691041655
725	t	1099.1	4989920082
726	t	396.7	2046094067
727	f	1052.1	1787483748
728	t	588.9	4047156591
729	f	1309.1	9585476083
730	f	223.2	4759911649
731	f	600.5	2538436210
732	t	830.9	9935973089
733	t	1340	9132587691
734	f	790.9	9738351525
735	t	1702.9	3799916775
736	f	633.5	9309923844
737	t	1098.4	4989920082
738	f	397.3	9123828612
739	f	410.4	8904632561
740	t	621.7	4841610573
741	f	1142.2	7339762711
742	f	1779.6	7133178691
743	f	1520.2	8251948425
744	f	1728.8	5414574014
745	f	1772.6	4792680958
746	f	1369.3	4841176402
747	t	1200	3869516952
748	t	614.7	6894091393
749	t	1634.8	4089662631
750	f	164.4	8528523141
751	f	630.5	3118548267
752	f	1513.5	7292034606
753	f	505.8	6215023273
754	t	260	8861652928
755	f	220.6	8803560704
756	f	1586.6	4671593782
757	t	1705.2	7993841582
758	f	1877.3	8242924095
759	t	843.7	9189105679
760	f	1965.3	5851505528
761	t	767.8	6276448037
762	f	1815.6	8956513466
763	t	764	3065170512
764	f	1166.9	6923510168
765	f	1214.8	9093056330
766	f	1526.8	5903140057
767	f	623.2	9627309179
768	t	728.3	8272115711
769	f	1617	6132557719
770	t	685.7	9697615163
771	f	1535.6	2115780478
772	f	1699.2	9188317580
773	f	392.9	5965247191
774	f	1177.6	3271588363
775	f	409	5821580942
776	f	1882.4	4834888059
777	t	810.4	9836515217
778	t	1860.6	4879435059
779	t	806.1	6881065536
780	t	631.4	1018507240
781	f	1893.2	9532532910
782	f	482.6	8685422750
783	f	963.3	6543812703
784	f	1404.9	5553467371
785	t	325.2	5874994150
786	t	1704.8	1742261492
787	t	1183.3	6354414748
788	f	1215.6	9602561809
789	t	1312	5595942666
790	t	373.8	5082181214
791	f	1773.9	3887496952
792	f	379.8	8568944355
793	f	1995.6	4836532563
794	f	1702.9	3356007255
795	t	1082.5	3482033732
796	f	951.2	3373429666
797	t	1125.8	6463927840
798	t	1111.4	3687958626
799	t	1133.7	7824340522
800	t	1238.4	9411831388
801	t	1273.5	9966901445
802	f	1901.9	5373680804
803	t	317.8	8526459227
804	f	1844.5	1997054817
805	t	1162.8	2825892618
806	t	1220.4	6302254780
807	t	1593.5	5464390551
808	t	1970.7	8867461509
809	f	838.1	4128144950
810	t	1897.6	8091601034
811	f	1294	8242924095
812	t	1796.6	3673282719
813	t	1126.5	3598899365
814	t	1552.8	9976759129
815	t	1656.7	9112169779
816	f	773.1	4788035408
817	f	234.6	4952198609
818	f	505.8	8028799314
819	t	424.7	3014961615
820	t	345.1	5236530953
821	t	1748.4	4841176402
822	f	1895.9	3089001123
823	t	797.9	8219254801
824	t	1121.5	8867461509
825	f	1798.2	9978835059
826	f	1498.7	1997054817
827	t	1021.9	3651543473
828	t	659.9	8614933154
829	f	1761.6	9855873978
830	f	1498.6	8219254801
831	t	1474.5	6735137353
832	t	1160.3	6759024078
833	t	1545.2	9368191083
834	f	1784.1	5984618071
835	t	1068.1	5373680804
836	t	1170.2	1958904112
837	f	1381.9	6343580905
838	f	1039.9	8511071853
839	t	1710	5661972249
840	f	1096.1	9785488605
841	t	558.2	3141486705
842	f	689.9	6614662431
843	f	1671.5	5478553897
844	t	1678.1	4403818833
845	t	718.4	6245657288
846	f	1384	4644373989
847	t	1540.2	6052718192
848	f	645	2386193632
849	f	1326.2	7298828769
850	t	917.2	4997850630
851	t	420	4952198609
852	t	542.3	2115780478
853	f	558.7	7862017888
854	f	1418.2	9784062717
855	t	1137.8	4326115859
856	t	550.9	5062817978
857	f	332.3	1238437744
858	t	1632.1	6046428941
859	f	1598.7	9855873978
860	t	291.6	3313720402
861	f	1438.9	9784062717
862	t	991.7	6559027992
863	t	1102.5	8413593278
864	f	461	8605585298
865	t	1232.5	5316272178
866	t	346.4	8184910403
867	f	1500.2	9663210635
868	t	1706	3302277821
869	f	1039.5	7632072068
870	t	1554.9	4549532764
871	t	1665	2271502564
872	t	627.8	1701623086
873	f	1845	3646185432
874	f	1542.4	3222786068
875	f	1983.9	1141746423
876	f	1454.5	4786795693
877	t	1124.1	5421970405
878	f	507.1	8756852162
879	f	596.9	4025167203
880	t	1309.6	5629265405
881	t	1344.5	7186902225
882	f	1245	3646185432
883	t	1553.2	6417745480
884	f	515.6	6559027992
885	f	1122.8	2632597350
886	t	1196.4	7766817000
887	t	1591.8	7858317058
888	f	361.6	8187342429
889	f	984.9	3482033732
890	t	1332.3	6918791898
891	f	1421.1	4644373989
892	f	1900.2	8349792232
893	t	919.3	8605134392
894	f	384	7035834762
895	t	1272.9	3799916775
896	f	689.1	1803906796
897	f	1955.3	3678218880
898	t	1928.1	9017015731
899	t	255.4	4253714311
900	f	856.8	5355537266
901	t	1079.1	1024343092
902	f	266.3	9248058144
903	f	1659.6	4392426762
904	t	1441.8	9646541002
905	t	565.9	1881828915
906	t	702.1	7516285170
907	f	1011.7	6199819562
908	t	533.2	5132091871
909	f	571.3	8091601034
910	t	1820.6	8803560704
911	t	1949.2	3571810321
912	f	1766.2	8679328968
913	f	1466	9657561975
914	t	481.3	7325060405
915	t	1123.9	6296618810
916	t	456.3	4466398207
917	f	1149	3935962387
918	t	384	8679328968
919	t	1727.5	8076679592
920	t	1225.7	9663210635
921	f	1195	6302254780
922	f	1965.1	2161683643
923	t	601.4	3789406474
924	t	1205.4	2093460870
925	f	1533.9	5471414477
926	f	1084.5	1018507240
927	t	909.3	6695949843
928	t	1627.2	6614187681
929	t	748.7	9646541002
930	f	236.6	3746851529
931	t	1495.2	4404164486
932	t	1043.1	8605585298
933	f	898.8	9357771800
934	f	1082.2	6134354545
935	f	742.6	2834281151
936	t	1084.2	3049966784
937	f	1983.6	8756852162
938	f	796.7	3482033732
939	f	1922.4	8832280122
940	f	1248.6	6887870539
941	f	821.3	3467237729
942	t	251.9	7622973477
943	f	1126.5	8652458038
944	f	247	1558997612
945	t	266.6	2825892618
946	f	1338.6	5378195974
947	t	560.9	6852347850
948	t	1485.9	3293152802
949	t	781.3	6917628112
950	t	1701.7	8661702208
951	t	1689.8	9663210635
952	t	1622.6	3356492405
953	t	627.3	2619931406
954	t	1065.2	9362808407
955	t	786.4	3791303183
956	f	1590.6	1958904112
957	f	721.4	7858317058
958	t	1637.1	7088277795
959	f	801.8	4379068253
960	f	1671.8	4477748787
961	f	747.1	5884877924
962	t	466.2	3819860925
963	f	1311.6	8467417169
964	f	484	2519371945
965	f	1691.1	4066749292
966	t	1573.3	6918791898
967	f	1643.4	7225466619
968	f	1832.6	4836532563
969	f	1844.5	3466601382
970	t	1073	9978835059
971	t	527.1	5204280536
972	t	1454.4	4841610573
973	t	836.2	4989920082
974	t	1573.3	3176848862
975	t	510.6	9411662419
976	f	1797.2	1569794945
977	f	1615.6	3122829758
978	t	1168.7	3176848862
979	t	289.9	6098173545
980	f	1043	9188317580
981	t	1294.3	3466601382
982	f	1045.4	6792927951
983	f	1106.8	3271588363
984	f	1334.9	3293152802
985	t	1248.1	5851505528
986	f	1789	9966901445
987	t	403.7	3598899365
988	f	796.5	2181136612
989	f	1112.8	2615796239
990	t	1106.5	8325293792
991	f	1011.9	7632072068
992	f	918	1238437744
993	t	562.9	4997850630
994	t	588.5	3169358676
995	f	1353.3	4477748787
996	t	951.2	2115780478
997	f	914.5	7701558262
998	f	1062.1	1303198777
999	f	1092.2	5039808914
1000	t	1245.1	2973203837
1001	t	394.9	7167879338
\.


--
-- TOC entry 4861 (class 0 OID 24644)
-- Dependencies: 220
-- Data for Name: storage_location; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage_location (location_id, line_storage, rack, shelf, box_storage) FROM stdin;
1	1	right	1	1
2	2	right	2	2
3	3	left	3	3
4	4	left	4	4
5	5	right	5	5
6	6	right	6	6
7	7	left	7	7
8	8	left	8	8
9	9	left	9	9
10	10	right	10	10
11	11	right	11	11
12	12	left	12	12
13	13	right	13	13
14	14	right	14	14
15	15	right	15	15
16	16	right	16	16
17	17	left	17	17
18	18	right	18	18
19	19	left	19	19
20	20	right	20	20
21	21	right	21	21
22	22	right	22	22
23	23	left	23	23
24	24	left	24	24
25	25	left	25	25
26	26	left	26	26
27	27	left	27	27
28	28	left	28	28
29	29	left	29	29
30	30	right	30	30
31	31	left	31	31
32	32	left	32	32
33	33	right	33	33
34	34	right	34	34
35	35	right	35	35
36	36	right	36	36
37	37	right	37	37
38	38	left	38	38
39	39	right	39	39
40	40	right	40	40
41	41	left	41	41
42	42	right	42	42
43	43	right	43	43
44	44	right	44	44
45	45	right	45	45
46	46	right	46	46
47	47	right	47	47
48	48	left	48	48
49	49	left	49	49
50	50	left	50	50
51	51	left	51	51
52	52	right	52	52
53	53	left	53	53
54	54	left	54	54
55	55	left	55	55
56	56	left	56	56
57	57	left	57	57
58	58	right	58	58
59	59	right	59	59
60	60	left	60	60
61	61	right	61	61
62	62	right	62	62
63	63	left	63	63
64	64	left	64	64
65	65	left	65	65
66	66	right	66	66
67	67	left	67	67
68	68	right	68	68
69	69	left	69	69
70	70	right	70	70
71	71	left	71	71
72	72	right	72	72
73	73	right	73	73
74	74	right	74	74
75	75	right	75	75
76	76	right	76	76
77	77	right	77	77
78	78	left	78	78
79	79	left	79	79
80	80	left	80	80
81	81	right	81	81
82	82	left	82	82
83	83	left	83	83
84	84	right	84	84
85	85	left	85	85
86	86	right	86	86
87	87	left	87	87
88	88	left	88	88
89	89	right	89	89
90	90	right	90	90
91	91	right	91	91
92	92	left	92	92
93	93	right	93	93
94	94	right	94	94
95	95	right	95	95
96	96	left	96	96
97	97	left	97	97
98	98	left	98	98
99	99	left	99	99
100	100	left	100	100
101	101	left	101	101
102	102	left	102	102
103	103	right	103	103
104	104	left	104	104
105	105	left	105	105
106	106	left	106	106
107	107	right	107	107
108	108	left	108	108
109	109	left	109	109
110	110	right	110	110
111	111	left	111	111
112	112	left	112	112
113	113	right	113	113
114	114	right	114	114
115	115	right	115	115
116	116	left	116	116
117	117	right	117	117
118	118	right	118	118
119	119	right	119	119
120	120	right	120	120
121	121	right	121	121
122	122	right	122	122
123	123	left	123	123
124	124	right	124	124
125	125	right	125	125
126	126	right	126	126
127	127	left	127	127
128	128	left	128	128
129	129	left	129	129
130	130	left	130	130
131	131	right	131	131
132	132	left	132	132
133	133	right	133	133
134	134	left	134	134
135	135	right	135	135
136	136	left	136	136
137	137	left	137	137
138	138	right	138	138
139	139	left	139	139
140	140	left	140	140
141	141	left	141	141
142	142	left	142	142
143	143	left	143	143
144	144	left	144	144
145	145	right	145	145
146	146	right	146	146
147	147	right	147	147
148	148	right	148	148
149	149	left	149	149
150	150	right	150	150
151	151	left	151	151
152	152	left	152	152
153	153	right	153	153
154	154	right	154	154
155	155	right	155	155
156	156	left	156	156
157	157	left	157	157
158	158	left	158	158
159	159	left	159	159
160	160	right	160	160
161	161	right	161	161
162	162	right	162	162
163	163	left	163	163
164	164	right	164	164
165	165	right	165	165
166	166	right	166	166
167	167	right	167	167
168	168	left	168	168
169	169	left	169	169
170	170	left	170	170
171	171	left	171	171
172	172	left	172	172
173	173	left	173	173
174	174	left	174	174
175	175	left	175	175
176	176	left	176	176
177	177	left	177	177
178	178	right	178	178
179	179	right	179	179
180	180	left	180	180
181	181	left	181	181
182	182	right	182	182
183	183	right	183	183
184	184	left	184	184
185	185	right	185	185
186	186	right	186	186
187	187	right	187	187
188	188	right	188	188
189	189	left	189	189
190	190	left	190	190
191	191	right	191	191
192	192	right	192	192
193	193	right	193	193
194	194	left	194	194
195	195	right	195	195
196	196	left	196	196
197	197	left	197	197
198	198	right	198	198
199	199	right	199	199
\.


--
-- TOC entry 4866 (class 0 OID 24717)
-- Dependencies: 225
-- Data for Name: transanction_decomposition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transanction_decomposition (transaction_id, product_id) FROM stdin;
928	31594170464847952796
66	78671291195212537915
965	66077015429694459659
734	62287161774993616383
864	99354381272648112919
799	54853912202188399126
92	21966639857194426663
267	92337089822534345749
108	12673709112068252577
976	58741149622098125403
865	87829837097071319254
660	41645071154998215293
526	53161016545444028997
544	28041673265766389928
634	47669389765992590267
63	72318062889075940609
63	10096814306539723218
230	82955853507036373915
603	66077015429694459659
11	79416135925428732632
141	97583430885302822791
791	26696663976515330445
549	69345241791823909452
855	73993263425493966761
436	75691709666436093055
568	60826801235938095758
384	57459670243966247067
381	99225974978542594965
906	14731677072942578425
571	99225974978542594965
129	17745404169904103791
780	86270227647356375718
733	17850341859627238240
211	24990437609995617386
737	78644765591077027566
912	85637528593536641053
770	32495317132389948354
710	23963483847331305514
168	89645461293314324858
157	99835224847032354814
103	54771144759559984985
695	62327794269641146394
790	10045407233135594944
541	87171242176586325717
993	94566847137164678292
196	24966088728236203698
403	74713783924015505807
640	67056312462259907572
625	54296548357078299205
460	65364078114706051991
842	47284640541326188910
410	33099332103082057699
675	61353927291378171390
379	68565067285125362900
203	99734390887542850190
433	41958662262959206418
715	48211437443256730075
902	18517647488768408659
305	47011144353383878632
879	47011144353383878632
408	99421713222217430139
418	95543944755164415045
181	80160645978126198546
557	58411454309436351460
954	85250927214087323781
884	47154166871049449060
843	28772288626246337495
29	42113784983704144293
713	55151277871195376701
493	47582828714644185051
723	15676144992779831681
148	82955456451008424391
541	61353927291378171390
401	48338734344906773805
542	51599107743931156515
912	47244981642258550490
393	29691261268081054524
584	10135128987491017103
608	66857947997066363396
917	47950360371712046008
756	33632180577829064888
954	48553642596277720448
228	47011144353383878632
873	92898023995112292982
480	60820991902817551587
456	88952164361732092874
382	18484050243566070510
153	50895687733984331792
666	27436935826114137773
817	24571826221536859581
714	10486696915226888421
862	10211633441569337700
260	83540377737568652190
972	75547288359756237899
731	55813026276212424547
508	71386977801977278856
502	89769817202496245873
275	21036861959661348962
163	26542843535586146586
874	28971283114167963671
239	92918425626246551920
910	43011950098713534592
131	56995649583521229739
15	80485334789359694965
91	60693868698508837323
204	18740971739866728630
274	56379453711848265330
477	41257807996294939649
685	94787877713532070198
713	18860805682521108165
63	41172869201054650272
66	86564578713416920457
307	96514406572854989169
687	42492380432619485752
854	46184991984627001057
810	68565067285125362900
846	81174482711528267335
640	96581521491446260371
823	70265265952422474453
192	30114263371952152218
323	55235929147364143672
43	81815985435122529776
528	88938807373451575602
152	80047767369556984421
37	49115675076045298247
601	39126085609981482204
946	51336911574101221346
487	21543321471573972494
939	43487153998662785637
896	23479262575183161116
602	13866033041612262091
229	91317060494974343875
803	25055189885275699628
730	48174564531245838017
864	39091904468351514766
320	75924225488733532854
463	16236445997082997661
227	19860512119465615991
116	35440225239511018625
22	95196288316066948301
329	17376387293809570116
386	53880140182359604754
873	56865534312487182119
963	48645348321901411430
346	20864442139713765364
587	77078629354295829645
764	14322212236263099066
326	42620705048144646512
747	81031472361286543396
155	31921960985743998510
793	11771633623971917029
534	34333792075828682509
118	68299676113858722608
256	99734390887542850190
958	28868531826471534318
946	38687566444319494112
138	66366789489377062432
563	48484672639304520071
892	25055189885275699628
957	60166170758098444097
196	30153294134409841517
456	68299676113858722608
15	96215277428841817299
56	78926935083804601900
895	94787877713532070198
199	87980005733275836028
132	75997943345083089169
308	25577276898169117781
845	12287939396715360695
869	20930003284595239827
185	17277665512391882359
849	33070288159998782286
446	47139052081135137536
350	84361692202022645182
765	18531878712316738774
40	92993565622772482488
668	85197112233635080111
771	58353973901366685465
811	69629291089799950152
233	14491696538829222048
718	88366137466594627190
218	72719738296343141158
347	53161016545444028997
927	26910719202632091441
46	59419186449743833707
630	38524611732797555454
591	91289355249817665228
330	64248939259967146339
113	58185897677045036140
871	26775370898248980506
286	70536906899072437800
180	18484050243566070510
273	36333353583667324510
198	52249238853299609237
770	19099459723496574832
471	77219210877569547718
839	33632180577829064888
221	58920116875589819432
706	26542843535586146586
759	63433450698759039688
688	17365087676808887863
844	77078629354295829645
286	35599214784778644293
536	12913530048217085972
318	23377279997798187422
36	87972437832029424715
711	34049180545435961020
105	32799915799482797337
221	99623973656349551490
217	63130195853366069521
171	61583827898211520231
84	34588791402124961386
233	11779664296606608817
445	23479262575183161116
178	22234181706738757571
676	58920116875589819432
114	85258203643408550153
570	13986645341162693329
641	54853912202188399126
230	62170487068456343371
485	51677121159101224615
658	69110480314697804152
151	97751229367115427459
104	91289355249817665228
589	74932249043524208476
472	63959415321227754155
571	46184991984627001057
163	23066362073039076012
374	42257143349107270821
741	40012500289563600327
883	32159273686488233087
550	61480961515264888594
425	33081499745441949992
815	65361607716618046632
26	29154150449644006157
600	40396475686229570570
914	20818732968504737016
408	18742606353238632303
309	81681630964108147122
880	66366789489377062432
685	50851753004184219794
199	99634903944341107593
336	40012500289563600327
372	30114263371952152218
530	65547482823687792467
85	30210969854815320794
995	88952164361732092874
527	57747898511276596044
52	80290801619071150355
707	54174095402517123368
310	41361126235012281386
262	92870263099005686414
844	70232799415912772922
46	67412196562757920453
653	65259386861738732364
566	11465572081597378618
388	69011843642422880968
543	76559212229971190996
498	19341827859552287077
906	21036861959661348962
19	59979910798973525441
362	86161141635709794637
960	20585741963507254518
606	24456768269373211538
538	35646500027531988639
870	36295028892425624085
373	84946890907325014283
357	26194750292482516160
631	34584467329618509701
341	33081499745441949992
391	41066629734225214151
955	54296548357078299205
418	95552632211866422428
653	67726851997067219285
303	18860805682521108165
122	66976193545323203689
466	83913776681723538381
546	55376183994519225701
553	56158873779171288859
186	21321925836845362802
704	32799915799482797337
505	31827851777489997287
714	86624867717425358344
46	53456501801938021193
713	23931265793293092286
922	50471597781198280281
84	15676144992779831681
473	35451394287059400802
726	14165713888069153427
579	30918446844728905014
785	95710260076293654514
593	79416135925428732632
891	65364078114706051991
138	83540377737568652190
922	91289355249817665228
82	90716396634257478813
30	80485334789359694965
723	87972437832029424715
153	93144821531472408170
594	69513148135515298447
866	36333353583667324510
352	53161016545444028997
758	87980005733275836028
192	77816382219167885176
176	26696663976515330445
759	67412196562757920453
535	76419381962739409875
846	85952772669967730032
772	48338734344906773805
992	84368567259323289945
211	35026523489036698547
757	56995649583521229739
842	19898867106763321129
725	22959942987865022736
480	25880144944698547099
912	71386977801977278856
876	99230094404931961220
560	40943074336635990316
439	40984870044779192255
677	62917098713822522590
446	24397618678316609883
134	37014737539286712322
687	70232799415912772922
525	98199156848572447121
660	27958517482515095676
483	27958517482515095676
132	61480961515264888594
206	27856814612768105534
880	88587244859254400360
375	87171242176586325717
647	71593838152071186640
269	56838426196723188780
111	84092600127751304328
898	97583430885302822791
345	95677753047158215656
865	87775919345916759595
201	47857877064212970900
425	98535392361485570618
765	25558240292149770658
710	98815378095923231543
539	52144136685244096778
825	85646432287998552467
835	47621865883838881269
291	78671291195212537915
286	25273081245265994838
105	23321365194665818611
609	24384606327588875165
939	27226380365203348459
681	15567650243257121112
334	27958517482515095676
488	25959904088314511281
710	37387594949014753799
275	52255857944516158559
393	30312722176842934048
458	27742324515542854622
751	99491276346648348244
433	72318062889075940609
417	58890028951084406056
599	68299676113858722608
956	39431707441052035183
820	98189429145053112743
936	31831037178707498509
519	81728964677948701352
924	24966088728236203698
315	20231397648492595523
565	54168629108614291212
858	95623008192285863659
891	39642012155318217010
78	82955853507036373915
151	35943460983037020831
697	96581521491446260371
725	60979543751871031094
248	55798796554215358144
15	32475967154227864953
916	30416198747676517374
827	98186721447431275769
898	57677477481609268194
389	40911401503537481715
926	35353476538066120609
72	67555695196564315184
644	10023366964581734414
26	48211437443256730075
534	34180684953864436524
932	12311043925392987051
810	43011950098713534592
774	33876846168656157908
529	72086529801707562674
954	18462243791941175835
387	33940500284279878099
864	56327774224604844090
581	27226380365203348459
318	76773640057607483991
104	84834616165585058335
583	90241930777496728469
387	23473103276576697192
533	89722476281549698167
742	96336673226123237159
118	15567650243257121112
439	39954208669236153473
790	89671887964388059617
865	52149825622891715018
367	78859602932854557406
223	48336803715176899770
316	57750053283425946203
598	11595830089457469836
382	88973708334372339554
554	30054255547279971967
887	13671893734544743798
111	35440225239511018625
155	66339624809506184375
264	95623008192285863659
510	88938807373451575602
972	85197112233635080111
283	19099459723496574832
263	42620705048144646512
648	16236445997082997661
307	47154166871049449060
457	79611395519071639114
652	10711737528241898512
663	36227356088978741179
589	53520891789664747933
346	57493003973957315338
870	62966590341968820036
585	97826793674518225347
269	87829837097071319254
82	48553642596277720448
463	70154172802241516175
735	28772288626246337495
904	82955456451008424391
618	34588791402124961386
150	67860984366873634386
730	35026523489036698547
402	40911401503537481715
170	66753936564367206516
981	74829481909127337519
586	56850708844037393633
833	98189429145053112743
952	35440225239511018625
934	30190895335358568368
404	85191287331856137499
635	12311043925392987051
250	20623396573285662019
37	64876833167331592651
549	25577276898169117781
428	30054255547279971967
685	98836405046873418628
468	35721587913118699265
97	87556326428601378673
638	30596231562375490584
703	90325240386579354808
93	41151860566325037803
316	99530641057402513361
573	13986645341162693329
765	84834616165585058335
615	25442887598725500534
562	13634721718818138629
876	61397225548377446882
247	41257807996294939649
591	88572947651812551034
523	12769413153618087949
85	13177253343887977438
987	83569105069648796907
768	63130195853366069521
721	98315400837642415481
964	86725797972796500748
932	25273081245265994838
787	35721587913118699265
768	98836405046873418628
829	95270313889384793688
72	93247502065838057371
313	52136652207501359159
444	45642330261916473572
729	13866033041612262091
711	11649070217776178330
496	37962685572861412718
844	63130195853366069521
14	61583827898211520231
54	42559344631183989283
572	47552904598572196782
93	85952772669967730032
6	27742324515542854622
461	71168070091156383846
913	15539015001073059407
840	69110480314697804152
362	37548485213899195764
81	92993565622772482488
93	96116969014456641358
93	20888095645125187717
926	25273081245265994838
339	14585091052674798014
80	58685653537046872592
274	16458404933682222969
395	34819715149905450630
719	65361607716618046632
761	79611395519071639114
796	21015621332979613015
603	31831037178707498509
996	76883871441947935915
788	51916374121906395514
33	58830923352962490618
667	46832416383587275090
241	37014737539286712322
844	63959415321227754155
900	37548485213899195764
137	72086529801707562674
752	42257143349107270821
544	47950360371712046008
585	84946890907325014283
144	50471597781198280281
322	54272383824955803117
426	42113784983704144293
711	62966590341968820036
781	63318148705247619331
396	51421140669847229877
581	38544549459436140276
998	71593838152071186640
974	28041673265766389928
73	88366137466594627190
602	85637528593536641053
323	43139577108923892374
80	16523158406032492368
462	55813026276212424547
665	25188437489421938784
826	22614877928074155835
812	38544549459436140276
948	53670055905443800210
544	49245682415743147124
311	31977638364914444502
280	56158873779171288859
694	17344860548772651284
438	95543944755164415045
713	74991937857548858201
220	78859602932854557406
472	86725797972796500748
148	34997087476807211693
489	20595516497381388526
603	52255857944516158559
154	55998297118366203331
24	57639167581686051765
593	36491418263862459581
351	48336803715176899770
279	83913776681723538381
878	55091574257563579473
389	31827851777489997287
614	18531878712316738774
695	22176533265211627526
146	96514406572854989169
579	80499463734232199538
640	17850341859627238240
105	44876412637756013139
777	88587244859254400360
321	31015630756776522708
431	46583964354461231370
477	87484620608562731602
392	11623069661457659198
583	12913530048217085972
264	81174482711528267335
621	43397104012961943856
827	41076878909759193745
917	83387201503868147006
664	94675106649025456295
625	26020074243404585960
220	85197112233635080111
540	73993263425493966761
640	80039019349908775897
567	99530641057402513361
983	56838426196723188780
275	25188437489421938784
299	85197112233635080111
575	10711737528241898512
42	68565067285125362900
702	57984463234993102582
326	45831254313871235818
447	24558145911557021214
36	82468043197251757581
337	34588791402124961386
970	95623008192285863659
629	47669006973738215092
238	58741149622098125403
386	13866033041612262091
385	16458404933682222969
75	54160927787356665384
571	81843310412806885816
678	23931265793293092286
716	41645071154998215293
944	38265899027435475190
396	90519029815209595812
727	67150245031535295849
369	96116969014456641358
913	40688322954334474324
610	46025993212053860497
415	50186035627339490939
935	74014915646446446237
301	56944356592043445793
850	55813026276212424547
96	74194498352915837913
432	37548485213899195764
486	76419381962739409875
369	34112008471162708112
664	29581223918178767046
632	96514406572854989169
932	45831254313871235818
225	85881052956688407770
459	84946890907325014283
444	48640769707348962941
476	17365087676808887863
559	75924225488733532854
497	30918446844728905014
510	27910430002856366854
746	22959942987865022736
638	56850708844037393633
249	17365087676808887863
373	40170179087792050140
146	24384606327588875165
617	92445476606673435391
930	72231673744628073262
102	98098208251118613877
685	96355495053848219932
554	11636984977219219610
716	45440691247159419365
439	84361692202022645182
458	66976193545323203689
355	99634903944341107593
452	18783570351111816235
311	24456768269373211538
766	37213472618392549507
891	19894463646234837626
796	72318062889075940609
485	64876833167331592651
497	34819715149905450630
446	12252346471779746918
587	43559808599678357523
468	63487945971433992337
409	26620404391116123784
593	16336819706505790475
664	45931252521034665610
85	67590860648653971069
248	35451394287059400802
850	20595516497381388526
585	96581521491446260371
853	22616961761829531810
813	32142082437644486422
336	54322036567127566521
280	32159273686488233087
507	31246394945317593617
758	70265265952422474453
951	32571730293764816732
89	97070947815253164890
279	73654639532919055173
338	21150979202641520635
632	29545384564221343516
538	96514406572854989169
454	81174482711528267335
144	21321925836845362802
276	17748248144351530847
850	98479853294702833343
407	72349605526391775954
25	51599107743931156515
675	56158873779171288859
392	36844460914488192951
223	66077015429694459659
460	16943518087203732123
822	84375815928064524300
834	61960018523569943903
915	83913776681723538381
340	13924269495907954904
799	61755212297054168285
650	68398601518231381947
613	28041673265766389928
127	92898023995112292982
275	13176485646226379386
186	41218005672065732346
833	24088759431018416166
693	96514406572854989169
712	12554021476984399633
686	60253522559726664883
903	55192309713172340294
168	33070288159998782286
104	13761810465442515500
153	81385995827712260776
316	40984870044779192255
512	41774008103986988401
573	41361126235012281386
177	37548485213899195764
108	20231397648492595523
72	80047767369556984421
639	98199156848572447121
520	13177253343887977438
239	29581223918178767046
230	19072788679446538474
315	35721587913118699265
228	35440225239511018625
349	96514406572854989169
662	96116969014456641358
443	94675106649025456295
82	87385598776022041633
550	13671893734544743798
508	92847043397751835757
387	20667867432721931817
504	29969718629164455800
878	55681441943878067374
131	82955456451008424391
341	20884147771558530910
795	54160927787356665384
512	81815985435122529776
968	54296548357078299205
613	58185897677045036140
319	36227356088978741179
236	63217569644232322448
669	17936039996991099130
946	25959904088314511281
9	84749147387982032902
317	35432341696521292206
938	62681531165746274633
82	35440675864754368212
177	19541503796492822607
943	58870826369478099072
78	47669389765992590267
71	57984463234993102582
118	67590860648653971069
268	30054255547279971967
242	49571211847267764248
301	99230094404931961220
183	43011950098713534592
678	86564578713416920457
10	54160927787356665384
888	74829481909127337519
856	31977638364914444502
248	40032185139117744426
95	20855033826121827285
300	30488308678012009703
431	30918446844728905014
730	19029483603132158697
156	66949761903963275973
433	66673440546087679287
163	25577276898169117781
912	97278537975918347490
142	22614877928074155835
270	38687566444319494112
888	55419263831832868752
122	32831958656809437623
63	11059750445687760104
7	67298313369776447989
909	66339624809506184375
651	27727526129962666596
379	76872485132392893697
117	26620404391116123784
5	20730166132051267908
169	24558145911557021214
73	98815378095923231543
640	34588791402124961386
351	15552052176787784142
592	24088759431018416166
73	83387201503868147006
270	20623396573285662019
410	11595830089457469836
604	34112008471162708112
934	60622481271883904344
490	76350336209313362731
69	57322948488288299907
17	53880140182359604754
534	41218005672065732346
115	55376183994519225701
389	63114474235869907352
199	11059750445687760104
944	95896543808677541620
934	69249159555405926110
286	23172045667563332142
565	46583964354461231370
967	80011333335377828828
397	95596615269763926231
324	83487075014973884232
173	13924269495907954904
352	72349605526391775954
377	47813799339862490416
134	23681423291623055040
720	61397225548377446882
406	65069563712736288560
44	47950360371712046008
370	87829837097071319254
124	39120259636911399781
954	12554021476984399633
106	92445476606673435391
869	41958662262959206418
932	21859323594064035181
665	18462243791941175835
703	69339139162413797895
152	41041673188477121011
409	33081499745441949992
104	48211437443256730075
75	65781718541841626219
217	14165713888069153427
19	93037327223799333690
318	81681630964108147122
795	69629291089799950152
48	56620448565586878024
7	24226997786603561933
905	56158873779171288859
44	70845080692027488056
815	20231397648492595523
110	69062961819746893057
675	97583430885302822791
96	30416198747676517374
424	55284185408882429552
597	82955456451008424391
601	66087290861022866312
717	62327794269641146394
232	25442887598725500534
919	72746319265964229955
268	77137476487703077313
461	85015729193763069986
781	17229048585235339187
716	76736647774645853068
852	95622667837294618729
696	20667867432721931817
686	38524611732797555454
121	24850863658036212079
431	51336911574101221346
527	97826793674518225347
173	62351082909151025518
448	40460818927676709711
690	27436935826114137773
399	31594170464847952796
942	64383257223195866584
986	62287161774993616383
616	33070288159998782286
808	84368567259323289945
313	84834616165585058335
804	36178710263771639523
720	65547482823687792467
186	62675645746909038456
456	61480961515264888594
300	39446346593805650871
332	28575886814478196213
113	43139577108923892374
179	23377279997798187422
693	97113466622391642870
409	53860788174667853754
947	78718576097233328874
492	35721587913118699265
850	94919140185789780694
855	57677477481609268194
984	45597103291841204824
911	51677121159101224615
660	40214492657478338801
600	17899909794402890507
610	76680065365011093792
710	56865634552962814468
990	69629291089799950152
949	62327794269641146394
146	40688322954334474324
231	14945615294786872374
705	15823667734762482687
293	79611395519071639114
784	99354381272648112919
543	52144136685244096778
336	70911466351284283799
709	57639167581686051765
7	77816382219167885176
463	61755212297054168285
974	31396518758055534822
847	61491831737611100068
780	31257256312632843564
87	70536906899072437800
680	45931252521034665610
145	51775049432651657998
470	31396518758055534822
308	89758332622114210285
636	62713624305819953482
106	27436935826114137773
212	70154172802241516175
720	24990437609995617386
85	34540442659147994721
733	95196288316066948301
561	95623008192285863659
950	47934401402686846944
307	75547288359756237899
119	13176485646226379386
327	52935292359091133447
999	60960347056015270140
728	47011144353383878632
484	15567650243257121112
170	33940500284279878099
959	97070947815253164890
50	69249159555405926110
513	33940500284279878099
851	71132751782128004984
928	17628031431296861168
55	40460818927676709711
634	90241930777496728469
46	24226997786603561933
\.


--
-- TOC entry 4880 (class 0 OID 0)
-- Dependencies: 217
-- Name: drug_id_drug_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.drug_id_drug_seq', 5, true);


--
-- TOC entry 4881 (class 0 OID 0)
-- Dependencies: 223
-- Name: moving_drugs_id_transaction_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.moving_drugs_id_transaction_seq', 1001, true);


--
-- TOC entry 4882 (class 0 OID 0)
-- Dependencies: 219
-- Name: storage_location_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.storage_location_location_id_seq', 199, true);


--
-- TOC entry 4686 (class 2606 OID 24610)
-- Name: active_ingredient active_ingredient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_ingredient
    ADD CONSTRAINT active_ingredient_pkey PRIMARY KEY (trade_name);


--
-- TOC entry 4698 (class 2606 OID 24689)
-- Name: client client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (phone);


--
-- TOC entry 4688 (class 2606 OID 24620)
-- Name: drug_group drug_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drug_group
    ADD CONSTRAINT drug_group_pkey PRIMARY KEY (active_ingredient);


--
-- TOC entry 4691 (class 2606 OID 24633)
-- Name: drug drug_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drug
    ADD CONSTRAINT drug_pkey PRIMARY KEY (id_drug);


--
-- TOC entry 4695 (class 2606 OID 24672)
-- Name: individual_product individual_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individual_product
    ADD CONSTRAINT individual_product_pkey PRIMARY KEY (sni);


--
-- TOC entry 4700 (class 2606 OID 24696)
-- Name: moving_drugs moving_drugs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moving_drugs
    ADD CONSTRAINT moving_drugs_pkey PRIMARY KEY (id_transaction);


--
-- TOC entry 4684 (class 2606 OID 24740)
-- Name: moving_drugs phone_check; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.moving_drugs
    ADD CONSTRAINT phone_check CHECK (((phone)::text ~ '^[0-9]{10}$'::text)) NOT VALID;


--
-- TOC entry 4702 (class 2606 OID 24721)
-- Name: transanction_decomposition prkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transanction_decomposition
    ADD CONSTRAINT prkey PRIMARY KEY (transaction_id, product_id);


--
-- TOC entry 4693 (class 2606 OID 24649)
-- Name: storage_location storage_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_location
    ADD CONSTRAINT storage_location_pkey PRIMARY KEY (location_id);


--
-- TOC entry 4696 (class 1259 OID 24764)
-- Name: client_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX client_index ON public.client USING btree (city, street);


--
-- TOC entry 4689 (class 1259 OID 24763)
-- Name: drug_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX drug_index ON public.drug USING btree (maker);


--
-- TOC entry 4703 (class 2606 OID 24621)
-- Name: active_ingredient active_ingredient_active_ingredient_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_ingredient
    ADD CONSTRAINT active_ingredient_active_ingredient_fkey FOREIGN KEY (active_ingredient) REFERENCES public.drug_group(active_ingredient);


--
-- TOC entry 4704 (class 2606 OID 24634)
-- Name: drug drug_trade_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drug
    ADD CONSTRAINT drug_trade_name_fkey FOREIGN KEY (trade_name) REFERENCES public.active_ingredient(trade_name);


--
-- TOC entry 4705 (class 2606 OID 24673)
-- Name: individual_product individual_product_id_drug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individual_product
    ADD CONSTRAINT individual_product_id_drug_fkey FOREIGN KEY (id_drug) REFERENCES public.drug(id_drug);


--
-- TOC entry 4706 (class 2606 OID 24678)
-- Name: individual_product individual_product_storage_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individual_product
    ADD CONSTRAINT individual_product_storage_location_id_fkey FOREIGN KEY (storage_location_id) REFERENCES public.storage_location(location_id);


--
-- TOC entry 4707 (class 2606 OID 24697)
-- Name: moving_drugs moving_drugs_phone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moving_drugs
    ADD CONSTRAINT moving_drugs_phone_fkey FOREIGN KEY (phone) REFERENCES public.client(phone);


--
-- TOC entry 4708 (class 2606 OID 24727)
-- Name: transanction_decomposition transanction_decomposition_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transanction_decomposition
    ADD CONSTRAINT transanction_decomposition_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.individual_product(sni);


--
-- TOC entry 4709 (class 2606 OID 24722)
-- Name: transanction_decomposition transanction_decomposition_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transanction_decomposition
    ADD CONSTRAINT transanction_decomposition_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.moving_drugs(id_transaction);


-- Completed on 2024-05-13 20:48:48

--
-- PostgreSQL database dump complete
--

