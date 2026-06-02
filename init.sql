--
-- PostgreSQL database dump
--

\restrict 1jYB01UbrnadBlcUXjxivAg29GYLZaMIlhfzLYRM7Rvv1kFkqeLDmaH2DpflkYH

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-04-28 23:28:59

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 266 (class 1255 OID 16749)
-- Name: add_work_progress_simple(integer, integer, integer, integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_work_progress_simple(p_id_sourse integer, p_all_perimeter integer, p_complete_perimeter integer, p_remained_perimeter integer, p_comment text, p_violations jsonb) RETURNS TABLE(id integer, message text, violations_count integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_work_progress_id INT;
BEGIN
    -- 1. вставка
    INSERT INTO work_progress (
        id_sourse,
        all_perimeter,
        complete_perimeter,
        remained_perimeter,
        comment,
        created_at
    )
    VALUES (
        p_id_sourse,
        p_all_perimeter,
        p_complete_perimeter,
        p_remained_perimeter,
        p_comment,
        CURRENT_TIMESTAMP
    )
    RETURNING work_progress.id INTO v_work_progress_id;

    -- 2. нарушения
    IF p_violations IS NOT NULL THEN
        INSERT INTO work_progress_violations (
            id_work_progress,
            id_article,
            object_a_week,
            new_violations,
            old_violations
        )
        SELECT
            v_work_progress_id,
            (v->>'IdArticle')::INT,
            (v->>'ViolationsWeek')::INT,
            (v->>'NewViolations')::INT,
            (v->>'OldViolations')::INT
        FROM jsonb_array_elements(p_violations) v;
    END IF;

    -- 3. возврат
    RETURN QUERY
    SELECT
        v_work_progress_id,
        'OK',
        COALESCE(jsonb_array_length(p_violations), 0);
END;
$$;


ALTER FUNCTION public.add_work_progress_simple(p_id_sourse integer, p_all_perimeter integer, p_complete_perimeter integer, p_remained_perimeter integer, p_comment text, p_violations jsonb) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 16773)
-- Name: get_dashboard_data(timestamp without time zone, timestamp without time zone, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_dashboard_data(date_from timestamp without time zone, date_to timestamp without time zone, year_select integer, month_select integer, quartal_select integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(

        'perimeter_by_source', COALESCE((
            SELECT json_agg(row_to_json(t))
            FROM (
                SELECT 
                    s.source,
                    SUM(wp.all_perimeter)::numeric AS sum
                FROM work_progress wp
                LEFT JOIN sourse s ON s.id = wp.id_sourse
                WHERE
                    (date_from IS NULL OR wp.created_at >= date_from) AND
                    (date_to IS NULL OR wp.created_at <= date_to) AND
                    (year_select IS NULL OR EXTRACT(YEAR FROM wp.created_at) = year_select) AND
                    (month_select IS NULL OR EXTRACT(MONTH FROM wp.created_at) = month_select) AND
                    (quartal_select IS NULL OR EXTRACT(QUARTER FROM wp.created_at) = quartal_select)
                GROUP BY s.source
            ) t
        ), '[]'::json),

        'daily_stats', COALESCE((
            SELECT json_agg(row_to_json(t))
            FROM (
                SELECT 
                    DATE(wp.created_at) AS date,
                    SUM(wp.all_perimeter)::numeric AS all_perimeter,
                    SUM(wp.complete_perimeter)::numeric AS complete_perimeter,
                    SUM(wp.remained_perimeter)::numeric AS remained_perimeter  -- ✅ FIX
                FROM work_progress wp
                WHERE
                    (date_from IS NULL OR wp.created_at >= date_from) AND
                    (date_to IS NULL OR wp.created_at <= date_to) AND
                    (year_select IS NULL OR EXTRACT(YEAR FROM wp.created_at) = year_select) AND
                    (month_select IS NULL OR EXTRACT(MONTH FROM wp.created_at) = month_select) AND
                    (quartal_select IS NULL OR EXTRACT(QUARTER FROM wp.created_at) = quartal_select)
                GROUP BY DATE(wp.created_at)
                ORDER BY DATE(wp.created_at)
            ) t
        ), '[]'::json),

        'violations', COALESCE((
            SELECT json_agg(row_to_json(t))
            FROM (
                SELECT 
                    a.article,
                    COALESCE(wpv.object_a_week, 0)::numeric AS object_a_week,
                    COALESCE(wpv.new_violations, 0)::numeric AS new_violations,
                    COALESCE(wpv.old_violations, 0)::numeric AS old_violations
                FROM work_progress_violations wpv
                LEFT JOIN work_progress wp ON wpv.id_work_progress = wp.id
                LEFT JOIN article a ON a.id = wpv.id_article
                WHERE
                    (date_from IS NULL OR wp.created_at >= date_from) AND
                    (date_to IS NULL OR wp.created_at <= date_to) AND
                    (year_select IS NULL OR EXTRACT(YEAR FROM wp.created_at) = year_select) AND
                    (month_select IS NULL OR EXTRACT(MONTH FROM wp.created_at) = month_select) AND
                    (quartal_select IS NULL OR EXTRACT(QUARTER FROM wp.created_at) = quartal_select)
            ) t
        ), '[]'::json)

    ) INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION public.get_dashboard_data(date_from timestamp without time zone, date_to timestamp without time zone, year_select integer, month_select integer, quartal_select integer) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16788)
-- Name: select_p(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_p(date date) RETURNS TABLE(name character varying, squer numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT r.name, SUM(count_application)::numeric
    FROM public.robots_analitic ra 
    LEFT JOIN robots r ON r.id = ra.idrobots 
    WHERE ra.datestatistic = date 
    GROUP BY r.name 
    ORDER BY r.name;
END;
$$;


ALTER FUNCTION public.select_p(date date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 16402)
-- Name: addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.addresses (
    id integer NOT NULL,
    address text
);


ALTER TABLE public.addresses OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16401)
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.addresses_id_seq OWNER TO postgres;

--
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 221
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- TOC entry 244 (class 1259 OID 16637)
-- Name: article; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article (
    id integer NOT NULL,
    article character varying(150)
);


ALTER TABLE public.article OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16636)
-- Name: article_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_id_seq OWNER TO postgres;

--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 243
-- Name: article_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_id_seq OWNED BY public.article.id;


--
-- TOC entry 240 (class 1259 OID 16588)
-- Name: photos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.photos (
    id integer CONSTRAINT bpla_id_not_null NOT NULL,
    date_discharge date,
    confirmed_signs_of_violations integer,
    other_violations integer,
    new_violations integer,
    id_type integer
);


ALTER TABLE public.photos OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16587)
-- Name: bpla_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bpla_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bpla_id_seq OWNER TO postgres;

--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 239
-- Name: bpla_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bpla_id_seq OWNED BY public.photos.id;


--
-- TOC entry 220 (class 1259 OID 16394)
-- Name: districts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    name character varying(200)
);


ALTER TABLE public.districts OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16393)
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.districts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.districts_id_seq OWNER TO postgres;

--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 219
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- TOC entry 246 (class 1259 OID 16645)
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    id integer NOT NULL,
    employee character varying(200)
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16644)
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_id_seq OWNER TO postgres;

--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 245
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.id;


--
-- TOC entry 236 (class 1259 OID 16529)
-- Name: objects_for_apartmens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.objects_for_apartmens (
    id integer NOT NULL,
    name character varying(50)
);


ALTER TABLE public.objects_for_apartmens OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16528)
-- Name: objects_for_apartmens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.objects_for_apartmens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.objects_for_apartmens_id_seq OWNER TO postgres;

--
-- TOC entry 5094 (class 0 OID 0)
-- Dependencies: 235
-- Name: objects_for_apartmens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.objects_for_apartmens_id_seq OWNED BY public.objects_for_apartmens.id;


--
-- TOC entry 228 (class 1259 OID 16428)
-- Name: overfly_block1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.overfly_block1 (
    id integer NOT NULL,
    iddistric integer,
    idadress integer,
    quantitynewviolation integer,
    idviolation integer
);


ALTER TABLE public.overfly_block1 OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16427)
-- Name: overfly_block1_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.overfly_block1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.overfly_block1_id_seq OWNER TO postgres;

--
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 227
-- Name: overfly_block1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.overfly_block1_id_seq OWNED BY public.overfly_block1.id;


--
-- TOC entry 230 (class 1259 OID 16451)
-- Name: overfly_block2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.overfly_block2 (
    id integer NOT NULL,
    num_p_p integer,
    id_status integer,
    id_adress integer,
    id_distric integer,
    square double precision
);


ALTER TABLE public.overfly_block2 OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16450)
-- Name: overfly_block2_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.overfly_block2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.overfly_block2_id_seq OWNER TO postgres;

--
-- TOC entry 5096 (class 0 OID 0)
-- Dependencies: 229
-- Name: overfly_block2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.overfly_block2_id_seq OWNED BY public.overfly_block2.id;


--
-- TOC entry 232 (class 1259 OID 16494)
-- Name: robots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.robots (
    id integer NOT NULL,
    name character varying(70),
    short_name character varying(20)
);


ALTER TABLE public.robots OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16512)
-- Name: robots_analitic; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.robots_analitic (
    id integer NOT NULL,
    idrobots integer,
    datestatistic date NOT NULL,
    count_application integer,
    isactive boolean,
    data_analize jsonb
);


ALTER TABLE public.robots_analitic OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16511)
-- Name: robots_analitic_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.robots_analitic_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.robots_analitic_id_seq OWNER TO postgres;

--
-- TOC entry 5097 (class 0 OID 0)
-- Dependencies: 233
-- Name: robots_analitic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.robots_analitic_id_seq OWNED BY public.robots_analitic.id;


--
-- TOC entry 238 (class 1259 OID 16539)
-- Name: robots_apartaments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.robots_apartaments (
    id integer NOT NULL,
    date_start date,
    worked_out_by_the_algorithm integer,
    doubles integer,
    violations_detected_by_the_algorithm integer,
    no_violations_were_detected integer,
    vri_was_not_found integer,
    count_transferred_ka integer,
    is_transferred_to_ka boolean,
    date_transferred date,
    date_receipt date,
    total_objects_worked_out integer,
    confirmed_violations_new integer,
    confirmed_violations_previously integer,
    comment character varying(500),
    object_id integer
);


ALTER TABLE public.robots_apartaments OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16538)
-- Name: robots_apartaments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.robots_apartaments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.robots_apartaments_id_seq OWNER TO postgres;

--
-- TOC entry 5098 (class 0 OID 0)
-- Dependencies: 237
-- Name: robots_apartaments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.robots_apartaments_id_seq OWNED BY public.robots_apartaments.id;


--
-- TOC entry 231 (class 1259 OID 16493)
-- Name: robots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.robots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.robots_id_seq OWNER TO postgres;

--
-- TOC entry 5099 (class 0 OID 0)
-- Dependencies: 231
-- Name: robots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.robots_id_seq OWNED BY public.robots.id;


--
-- TOC entry 248 (class 1259 OID 16654)
-- Name: sourse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sourse (
    id integer CONSTRAINT source_id_not_null NOT NULL,
    source character varying(150)
);


ALTER TABLE public.sourse OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16653)
-- Name: source_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.source_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.source_id_seq OWNER TO postgres;

--
-- TOC entry 5100 (class 0 OID 0)
-- Dependencies: 247
-- Name: source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.source_id_seq OWNED BY public.sourse.id;


--
-- TOC entry 226 (class 1259 OID 16420)
-- Name: statusapplication; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statusapplication (
    id integer NOT NULL,
    name character varying(200)
);


ALTER TABLE public.statusapplication OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16419)
-- Name: statusapplication_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.statusapplication_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.statusapplication_id_seq OWNER TO postgres;

--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 225
-- Name: statusapplication_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.statusapplication_id_seq OWNED BY public.statusapplication.id;


--
-- TOC entry 242 (class 1259 OID 16620)
-- Name: type_photo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_photo (
    id integer NOT NULL,
    name character varying(10)
);


ALTER TABLE public.type_photo OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16619)
-- Name: type_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.type_photo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.type_photo_id_seq OWNER TO postgres;

--
-- TOC entry 5102 (class 0 OID 0)
-- Dependencies: 241
-- Name: type_photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.type_photo_id_seq OWNED BY public.type_photo.id;


--
-- TOC entry 224 (class 1259 OID 16412)
-- Name: violations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.violations (
    id integer NOT NULL,
    name character varying(200)
);


ALTER TABLE public.violations OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16411)
-- Name: violations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.violations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.violations_id_seq OWNER TO postgres;

--
-- TOC entry 5103 (class 0 OID 0)
-- Dependencies: 223
-- Name: violations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.violations_id_seq OWNED BY public.violations.id;


--
-- TOC entry 250 (class 1259 OID 16715)
-- Name: work_progress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_progress (
    id integer NOT NULL,
    id_sourse integer,
    all_perimeter integer,
    complete_perimeter integer,
    remained_perimeter integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    comment character varying(500)
);


ALTER TABLE public.work_progress OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16714)
-- Name: work_progress_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.work_progress_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.work_progress_id_seq OWNER TO postgres;

--
-- TOC entry 5104 (class 0 OID 0)
-- Dependencies: 249
-- Name: work_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.work_progress_id_seq OWNED BY public.work_progress.id;


--
-- TOC entry 252 (class 1259 OID 16731)
-- Name: work_progress_violations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_progress_violations (
    id integer NOT NULL,
    id_work_progress integer,
    id_article integer,
    object_a_week integer,
    new_violations integer,
    old_violations integer
);


ALTER TABLE public.work_progress_violations OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16730)
-- Name: work_progress_violations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.work_progress_violations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.work_progress_violations_id_seq OWNER TO postgres;

--
-- TOC entry 5105 (class 0 OID 0)
-- Dependencies: 251
-- Name: work_progress_violations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.work_progress_violations_id_seq OWNED BY public.work_progress_violations.id;


--
-- TOC entry 4839 (class 2604 OID 16405)
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- TOC entry 4850 (class 2604 OID 16640)
-- Name: article id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article ALTER COLUMN id SET DEFAULT nextval('public.article_id_seq'::regclass);


--
-- TOC entry 4838 (class 2604 OID 16397)
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- TOC entry 4851 (class 2604 OID 16648)
-- Name: employee id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- TOC entry 4846 (class 2604 OID 16532)
-- Name: objects_for_apartmens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.objects_for_apartmens ALTER COLUMN id SET DEFAULT nextval('public.objects_for_apartmens_id_seq'::regclass);


--
-- TOC entry 4842 (class 2604 OID 16431)
-- Name: overfly_block1 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block1 ALTER COLUMN id SET DEFAULT nextval('public.overfly_block1_id_seq'::regclass);


--
-- TOC entry 4843 (class 2604 OID 16454)
-- Name: overfly_block2 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block2 ALTER COLUMN id SET DEFAULT nextval('public.overfly_block2_id_seq'::regclass);


--
-- TOC entry 4848 (class 2604 OID 16591)
-- Name: photos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.photos ALTER COLUMN id SET DEFAULT nextval('public.bpla_id_seq'::regclass);


--
-- TOC entry 4844 (class 2604 OID 16497)
-- Name: robots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots ALTER COLUMN id SET DEFAULT nextval('public.robots_id_seq'::regclass);


--
-- TOC entry 4845 (class 2604 OID 16515)
-- Name: robots_analitic id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_analitic ALTER COLUMN id SET DEFAULT nextval('public.robots_analitic_id_seq'::regclass);


--
-- TOC entry 4847 (class 2604 OID 16542)
-- Name: robots_apartaments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_apartaments ALTER COLUMN id SET DEFAULT nextval('public.robots_apartaments_id_seq'::regclass);


--
-- TOC entry 4852 (class 2604 OID 16657)
-- Name: sourse id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sourse ALTER COLUMN id SET DEFAULT nextval('public.source_id_seq'::regclass);


--
-- TOC entry 4841 (class 2604 OID 16423)
-- Name: statusapplication id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statusapplication ALTER COLUMN id SET DEFAULT nextval('public.statusapplication_id_seq'::regclass);


--
-- TOC entry 4849 (class 2604 OID 16623)
-- Name: type_photo id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_photo ALTER COLUMN id SET DEFAULT nextval('public.type_photo_id_seq'::regclass);


--
-- TOC entry 4840 (class 2604 OID 16415)
-- Name: violations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.violations ALTER COLUMN id SET DEFAULT nextval('public.violations_id_seq'::regclass);


--
-- TOC entry 4853 (class 2604 OID 16718)
-- Name: work_progress id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress ALTER COLUMN id SET DEFAULT nextval('public.work_progress_id_seq'::regclass);


--
-- TOC entry 4855 (class 2604 OID 16734)
-- Name: work_progress_violations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress_violations ALTER COLUMN id SET DEFAULT nextval('public.work_progress_violations_id_seq'::regclass);


--
-- TOC entry 5053 (class 0 OID 16402)
-- Dependencies: 222
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.addresses (id, address) FROM stdin;
29	(г Москва, п Михайлово-Ярцевское, вблизи д. Терехово)
49	(г. Москва, парк по Борисовским прудам)
39	(город Москва, Рязановское поселение, д. Алхимово, ул. Сосновая, дом 5)
2	(Местоположение установлено относительно ориентира, расположенного в границах участка. Почтовый адрес ориентира: г Москва, ул Складочная, вл 3, стр 5, 9.)
8	(Местоположение установлено относительно ориентира, расположенного в границах участка. Почтовый адрес ориентира: г. Москва, территория Природно-исторического парка "Москворецкий", СЗАО г. Москвы.)
32	(Москва, п Сосенское, п Газопровод)
45	(Российская Федерация, г. Москва, вн.тер.г поселение Московский, д. Саларьево, ул. 2-я Новая)
7	(Российская Федерация, г. Москва, п. Марушкинское, д. Большое Свинорье)
987	(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Бирюлево Восточное, улица 3-я Радиальная, земельный участок 10Г )
47	(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Бирюлево Восточное, улица Липецкая, земельный участок 5А/2)
50	(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, улица Адмирала Корнилова, земельный участок 37)
3	(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Северное Медведково, проезд Чермянский, земельный участок 3)
5	(Российская Федерация, город Москва, вн.тер.г. поселение Кленовское, квартал 214, земельный участок 1)
31	(Российская Федерация, город Москва, вн.тер.г. поселение Сосенское, квартал 133)
9	(Российская Федерация, Москва, 2-я Кабельная ул )
153	15-й микрорайон г Зеленограда, корпус 1556
1045	1-й Иртышский проезд, вл. 8
79	1-й Курьяновский проезд
78	1-я Останкинская ул., зу 5/1
74	1-я Северная линия, зу 27/2
213	26656_г. Москва, ул. Электродная, земельный участок 8 (д. 8, стр. 3)
214	26658_г. Москва, МКАД 73-й км, вл. 7, корп. 1
215	26659_2660_ул Ижорская, вл 5
216	26661_г. Москва, ул. Яблочкова, д. 1
217	26663_ул. 16-я Парковая, вл. 22А, стр. 1
218	26664_г. Москва, б-р. Кронштадтский, вл. 20
219	26666_г. Москва, Курское направление железной дороги дополнительный участок №7 Г (смежный)
220	26668_город Москва, поселение Вороновское, вблизи с.Богоявление, снт "Меридиан", уч-к 127 с к.н. 50:27:0040404:200
221	26669_г. Москва, поселение Марушкинское, д. Соколово, уч-к 38 (вблизи земельных участков с кадастровыми номерами (50:26:0170806:10, 50:26:0170806:11)
222	26670_г. Москва, ул. Промышленная, вл. 9А, вл. 9А, стр. 1
223	26671_г. Москва, ул. Шаболовка, вл. 35
224	26674_Российская Федерация, г. Москва, вн.тер.г. поселение Кленовское, кв-л 302, вблизи з/у 1
225	26676_ул. Большая Косинская, вл. 18, стр. 1 - 6, 11, вл. 18А, стр. 1 - 5, 7 - 12
226	26678_г. Москва, пр. Сигнальный, вл. 37
227	26679_г. Москва, пос. Кленовское, вблизи дер. Старогромово, СНТ "Гавриково" (уточненный адресный ориентир: г. Москва, пос. Кленовское, вблизи дер. Старогромово, СНТ "Гавриково
81	26679_г. Москва, пос. Кленовское, вблизи дер. Старогромово, СНТ "Гавриково" (уточненный адресный ориентир: г. Москва, пос. Кленовское, вблизи дер. Старогромово, СНТ "Гавриково" вблизи з/у к/н 50:27:0030502:78
228	26680_(г Москва, Молдавская улица, вл 3)
229	26681_г. Москва, г. Щербинка, туп. Бутовский, вл.6А
82	26682_г. Москва, ул. Пехорская, вл. 5
230	26684_г. Москва, ул. Типографская, рядом
231	26687_ул. Смольная, вл. 24
232	26688_г. Москва, Долгопрудная аллея, вл. 2Б
233	26691_г. Москва, проезд Причальный
234	26692_г. Москва, пер. 1-й Щемиловский, вл. 16, стр. 2
235	26693_г. Москва, ул. 1-я Тверская-Ямская, вл. 29, стр. 3
236	26694_г. Москва, пер. Весковский, вл. 7
237	26695_г. Москва, проезд Михайловский, вл. 4, стр. 3 (рядом)
238	26696_г. Москва, пл. Таганская, вл. 86/1, стр. 1
239	26697_г. Москва, Большой Каретный переулок, вл 11
240	26699_г. Москва, Столярный переулок, вл. 5, стр. 1
241	26702_г. Москва, ул. Академика Челомея, вл. 7
242	26704_ул. Бирюлевская, вл. 38 (напротив)
243	26706_г. Москва, ул. Сущевская, вл. 21-23, стр. 2
1077	-
244	26712_г. Москва, промзона № 46 «Коровино» (пр. пр. 4938 и пр. пр. 5207)
245	26713_г. Москва, ул. Бажова, вл. 17, стр. 1, 4, 5, 6
246	26714_г. Москва, Коломенский проезд, вл.1В
247	26716_г. Москва, 1-й Тружеников пер., вл. 16, стр. 6
248	26717_г. Москва, ул. Большая Новодмитровская, вл. 23, стр. 1, 2, 8
249	26718_г. Москва, ул. Дубининская, вл. 33"Б"
250	26721_1-й Варшавский проезд, вл.1А, стр.9,39
251	26725_г. Москва, ул. Космонавта Волкова, вл.10
252	26726_г. Москва, г. поселение Марушкинское, деревня Марушкино, ул. Агрохимическая, з/у 4 (вблизи)
253	26727_(г. Москва, ул. Хлобыстова, вл. 5)
80	26728_г. Москва, поселение Вороновское, вблизи д. Косовка
254	26729_г. Москва, ЮВАО, район Люблино, ПРОМЗОНА "ЧАГИНО", ПР. ПР.4586, Д. 4
255	26730_г. Москва, ПР. ПР. 607, ВЛ. 8
256	26732_г. Москва, ул. Золоторожский Вал, вл. 6
257	26736_г. Москва, ул. Кирпичные Выемки, вл.5 (рядом)
258	26737_(Местоположение установлено относительно ориентира, расположенного в границах участка. Почтовый адрес ориентира: г Москва, проезд Строительный, вл 2.)
259	26743_ул. Косинская, рядом с вл. 3
260	26744_г. Москва, ул. Рабочая, вл. 91, стр. 2, 3, 4
261	26747_ул. Скаковая, вл. 36 (77:09:0005015:16)
262	26758_(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Покровское-Стрешнево, шоссе Волоколамское, земельный участок 65/2/1)
263	26761_г. Москва, район Люблино, ул. Ставропольская, вл. 37 (рядом)
264	26762_г.Москва, ЮВАО, р-н Текстильщики, ул. Грайвороновская, вл.9
265	26765_г. Москва, поселение Марушкинское, ЦУ с-за "Крекшино"/1-я очередь/ участок № 158 (рядом)
266	26768_г. Москва, поселение Московский, д.Мешково, ОНТ «Катюша»
267	26769_г. Москва, Высоковольтный пр., вл. 1, стр. 29
268	26770_г. Москва, Высоковольтный пр., вл. 1, стр. 25
269	26771_г. Москва, ул. Южнопортовая, вл. 38
270	26772_г. Москва, ЮВАО, район Кузьминки, Волжский б-р, вл. 51 (рядом)
271	26775_г. Москва, Высоковольтный проезд, вл. 9
272	26782_г. Москва, ул. Новоостаповская, вл. 6А
273	26783_г. Москва, ул. Павла Андреева, вл. 23
490	26786_26790_26820_ул. Кетчерская, рядом с вл. 11А, вл. 11Б
491	26787_г. Москва, ул. Генерала Белоборода, вл. 48
492	26789_г. Москва, ЮВАО, район Люблино, ул. Верхние поля, вл. 33В
493	26791_(г. Москва, поселение Новофедоровское, между СНТ «Рассудово», по границе г. Москвы и Московской области, п. Капустинка, по границе г. Москвы и Московской области, по руслу р. Пахра, д. Руднево, д. Кузнецово)
494	26792_г. Москва, ул., Лужская, рядом с вл.5.
495	26793_ул. Лыткаринская, з/у 21А/3 (рядом)
496	26795_г. Москва, ул. Азовская, вл. 35, рядом
497	26800_г. Москва, пос. Марушкинское, у пос. ОПХ Толстопальцево, СПК «Сад», вблизи з/у с к/н 50:26:0170506:14
498	26802_г. Москва, ул. Чагинская, вл. 6А, стр. 5 (смежный)
500	26805_г. Москва, Высоковольтный пр., вл. 1, соор. 46 и стр. 33
501	26807_г. Москва, Ленинградское шоссе, вл. 71Б
499	26810_г. Москва, поселение Марушкинское, п. Совхоза Крёкшино, д. 165, д. 165, к. 1
502	26811_ул. Котляковская вл.12
503	26812_г. Москва, поселение Рязановское, п. Фабрики им. 1 Мая
504	26813_ул. 6-я Радиальная, вл. 24, стр. 5; вл. 24, соор.1
505	26814_г. Москва, ул. Академика Янгеля, д. 11 стр. 50
506	26818_г. Москва, ул. Перерва, вл. 11, стр. 24 (смежный)
507	26819_г. Москва, ЮВАО, район Рязанский, ул. Окская, вл. 15
508	26824_26825_г. Москва, ул. 1-я Вольская, влд. 47
509	26828_г. Москва, пр-кт. Маршала Жукова, вл.4 (около)
511	26830_(Российская Федерация, г. Москва, вн.тер.г. пос. Краснопахорское, д. Красная Пахра, з/у 55Д)
512	26833_г. Москва, Даниловская наб., вл. 8
513	26836_Москва, Митино, Генерала Белобородова (вл. 46)
514	26837_г. Москва, ЮВАО, район Текстильщики, проезд Остаповский, вл 15/19
515	26850_г. Москва, ул. Новая Ипатовка, вл. 4 (рядом)
516	26851_г. Москва, ЮВАО, район Люблино, ул. Верхние поля, вл. 33г
518	26853_г. Москва, промзона № 46 «Коровино» (пр. пр. 4938 и пр. пр. 5207)
517	26854_г Москва, ул Мосфильмовская, вл 80А
519	26855_улица Cтарообрядческая, вл 28А
520	26856_г. Москва, пос. Щаповское, п. Щапово (вблизи з.у. с к.н. 50:27:0020207:40)
521	26857_улица Преображенский Вал, Дом 27
85	26859_г. Москва, ул. Новогорская, вл. 47
522	26864_г. Москва, Волоколамское шоссе, вл. 120
523	26865_г .Москва, ул. Складочная, вл. 3д, стр. 1, 2, 5, 6
524	26866_г. Москва, ул. Большая Почтовая, вл. 43-45, стр. 5, 12
525	26867_г. Москва, ул. 2-я Муравская, вл. 21, стр. 1
526	26874_г Москва, ул Новоорловская, напротив вл. 4
405	26878_г. Москва, ул. Никитинская, вл. 10Г
406	26879_г. Москва, ул. Плеханова, вл. 15А, вл. 17, стр. 2, 17
407	26883_(г. Москва, Зеленоград, пр-кт Генерала Алексеева, влд. 42, стр. 6, 7, 8, 9)
408	26885_г. Москва, ш. Долгопрудненское, вл. 5/1
409	26887_ул. Кетчерская, вл. 9
410	26889_г.Москва, Открытое шоссе, вл.10
411	26890_26891_г. Москва, пос. Новофедоровское, д. Зверево, ул. Лучистая, земельный участок 17, 15
412	26896_Г. Москва, ул. Нижняя Сыромятническая, вл. 1/4
413	26899_г. Москва, проезд Егорьевский, вл. 1А
414	26901_г. Москва, пер. Кривоколенный, вл. 4, стр. 3, 10
415	26902_(Местоположение установлено относительно ориентира, расположенного в границах участка. Почтовый адрес ориентира: г Москва, Малый Каретный переулок, вл 11-13, стр 1, 2, 3, 4, 10, 11.)
416	26904_г. Москва, ул. Севанская, вл.25А
417	26905_г. Москва, ул. Южнопортовая, вл. 40/1
421	26910_г. Москва, ЮВАО, район Выхино-Жулебино, ул. Привольная, вл. 10
422	26911_г.Москва, ул.1-я Вольская, вл.23
423	26914_г. Москва, ул. Складочная, вл. 20А, стр. 5
424	26923_Г. Москва, ш. Очаковское, вл. 36А
425	26924_г. Москва, ул. Южнопортовая, вл. 40
426	26925_Москва, пер Предтеченский Верхн., вл 11А
427	26927_г. Москва, 1-Рижский пер., вл. 6, стр. 1, 3, 4, 8
428	26930_г. Москва, ул. Николая Химушина, вл. 5, стр. 3,4
429	26936_г. Москва, вн.тер.г. поселение Десеновское, км. Калужское шоссе 31-й (п Десеновское), вблизи з/у с к/н 50:21:0150309:1242
430	26937_г. Москва, ул. Плеханова, вл. 10А
431	26938_г. Москва, Товарищеский пер., вл. 19
432	26943_г. Москва, пос. Московский, д. Мешково
433	26944_г. Москва, ул. Таманская, вл. 1
434	26949_г. Москва, пр-д 3-й Угрешский, вл. 6
435	26950_г. Москва, пл. Журавлева, вл. 1, стр. 1
436	26951_ул. Большая Косинская, вл. 18А/6
437	26953_г. Москва, ул. Краснолиманская, рядом
438	26963_ул. Липецкая, промзона «Ленино», участок 1 (рядом)
439	26965_г. Москва, ул. Зорге, вл. 5
440	26966_г. Москва, пересечение 34 км. МКАД с транспортной развязкой на Северное Бутово
441	26969_г. Москва, ул. Зорге, вл. 21
442	26972_г. Москва, ул. Академика Скрябина, вл. 21
443	26975_г. Москва, ТАО, поселение Вороновское, вблизи д. Юрьевка, НО Потребительский кооператив "ТИЗ "РУСЬ", уч-к 33
444	26981_г. Москва, проезд 2-й Перова Поля, вл 2
445	26982_г. Москва, проезд 3-й Силикатный, вл.3
446	26983_г. Москва, Промзона № 62 Теплого Стана, пр-зд Одоевского, вл. 3
447	26984_3-й Нижнелихоборский пр., вл. 3А, вблизи
448	26987_г. Москва, Зеленоград, Сосновая аллея, вл. 8
449	26988_(Местоположение установлено относительно ориентира, расположенного в границах участка. Почтовый адрес ориентира: г Москва, пр-кт Мира, вл 220а.)
450	26991_г. Москва, Остаповский пр-д, вл.26
451	26992_г. Москва, пр-д 3-й Угрешский, д. 10
883	27183_Новоухтомское шоссе, земельный участок 2А/1
885	27186_(г. Москва, Старокаширское шоссе, вл. 2, корп. 12)
884	27189_г. Москва, ул. Люблинская
886	27194_ул. Люблинская, вл.82
887	27195_Почтовый адрес ориентира: г Москва, ул Фабрициуса, вл 37
888	27205_г. Москва, ул. Самокатная, вл. 4А, стр. 1, стр. 2, стр. 10
889	27208_г. Москва, Огородный пр., вл.20а
890	27209_г. Москва, ЗелАО, ш. Фирсановское, вл. 15
891	27210_г. Москва, 2-й Кожуховский пр-д, вл. 12
892	27212_г. Москва, САО, Ленинградское ш., вл. 304
893	27213_г. Москва, Ленинградское ш., рядом с вл.295
894	27216_(Российская Федерация, город Москва, вн.тер.г. муниципальный округ Беговой, проспект Ленинградский, земельный участок 15/17)
895	27217_г. Москва, проспект Балаклавский
896	27218_г. Москва, Светлый проезд, (вблизи ЗУ с адрсеным ориентиром: проезд Светлый, вл. 2)
897	27219_(г. Москва, ул. Вятская, вл. 41)
898	27222_г. Москва, Дербеневская ул., вл. 22
899	27224_г Москва, 5-й микрорайон г ЗелАОа, корпус 514
900	27226_г. Москва, п. Вороновское, квартал №142, вблизи д. 4, стр. 1
901	27230_г. Москва, пр-д Огородный, вл. 8
902	27235_2-й Амбулаторный проезд, вл. 10
903	27239_г. Москва, ул. Южнопортовая, вл. 5, стр. 1-3
904	27242_(г. Москва, ул. Бирюлевская, вл. 37А)
906	27243_г. Москва, пр-д Проектируемый № 5113
905	27245_(г. Москва, Звенигородское шоссе, вл. 28, стр. 5)
907	27246_г. Москва, Канатчиковский пр-д, около вл. 7, корп. 1
908	27256_г. Москва, ул. Верейская, з-у 29-154А.
909	27257_г. Москва, улица Софьи Ковалевской, вл. 1
910	27260_г. Москва, ш. Фрезер, вл. 10 (рядом)
911	27262_г. Москва, Большой Волоколамский проезд, вл. 6
912	27263_г ЗелАО, проезд 2-й ЗАО, вл 2А, стр 4, 6, 7
913	27266_г. Москва, п. Вороновское, вблизи д. Львово.
914	27269_г. Москва, ул. Таманская, вл. 1, стр. 3
915	27273_27274_24275_г. Москва, пр-д Проектируемый № 4294, д. 19, пр.пр. 1481
916	27280_г. Москва, пл. Спартаковская, вл. 10, стр. 10,12-12А,14
917	27286_(г. Москва, ЗелАО, проезд № 4807, вл. 2, стр. 4)
918	27287_г. Москва, пер. Елизаветинский, вл. 10/2, стр. 3
109	27811_г. Москва, ш. Пятницкое вл. 2 (рядом)
110	27814_г Москва, ул Нижняя, вл 14
111	27815_Российская Федерация, город Москва, вн.тер.г. поселение Воскресенское, деревня Губкино, земельный участок 78
112	27818_г. Москва, ул. Ленинская Слобода, вл. 26, стр. 55
113	27824_г Москва, ш Карачаровское, вл 15
115	27830_АДРЕСНЫЕ ОРИЕНТИРЫ ПРОМЗОНА КУРЬЯНОВО, ПРПР № 1481
116	27831_АДРЕСНЫЕ ОРИЕНТИРЫ: ПРОЕКТИРУЕМЫЙ ПРОЕЗД 4294 Д.19
117	27833_г. Москва, 3-й Угрешский проезд, вл. 11
118	27835_г Москва, ул Южнопортовая, вл 17А
119	27838_Российская Федерация, город Москва, внутригородская территория муниципальный округ Чертаново Южное, улица Кирпичные Выемки, земельный участок 2/1
120	27840_г. Москва, наб Лихоборская, з/у 20 (рядом)
121	27846_г. Москва, Алтуфьевское шоссе, вл. 27
122	27847_г. Москва, пос. Новофедоровское, д.Зверево, ул. Радужная, вблизи зу с кад. № 50:26:0140503:233
173	27857_город Москва, вн.тер.г. муниципальный округ Северное Медведково, проезд Чермянский, земельный участок 3
174	27859_г Москва, ул Вишневая, вл 13А, стр 1
175	27860_г Москва, г Зеленоград,ул Заводская, п Малино, вл 26А
176	27861_г. Москва, ул. Авиамоторная, земельный участок 19А9 (смежный)
177	27865_город Москва, поселение Первомайское, у дер.Поповка
178	27868_г Москва, ул Западная, вл 6
179	27872_г Москва, ул 6-я Радиальная
180	27873_Российская Федерация, г. Москва, вн.тер.г. муниципальный округ Куркино, ш. Куркинское, з/у 27/2/1
84	27874_г Москва, Куркинское шоссе, вл 27/39
181	27875_г. Москва, СЗАО, МК МЖД, участок № 6 (вблизи)
182	27877_г. Москва, улица Викторенко, вл. 18, стр. 1, 2, 3
183	27878_г. Москва, 3-й Лучевой просек, вл. 12, стр. 1, 6
184	27879_Российская Федерация, город Москва, вн.тер.г. поселение Воскресенское, деревня Губкино, земельный участок 78
185	27882_г. Москва, ул. Верхние Поля, вл. 51А
186	27884_г Москва, ш Каширское, вл 22, корпус 3
187	27885_г. Москва, ул. Барышиха, вл. 39
189	27887_г Москва, ул Сущевский Вал, вл 5, стр 22
190	27888_г. Москва, ул. Нагорная, вл. 3, стр. 10
191	27889_г Москва, ул Грайвороновская, дом 5
192	27890_г. Москва, ул. Михневская, вл. 1 77:05:0010004:242
193	27892_г. Москва, Березовая аллея, вл. 16А
194	27897_г Москва, г Зеленоград, Сосновая аллея, ЗУ 10/77/00150\n 27916_ Проезд № 4921
195	27901_г. Москва, ул. Перерва 19
83	27903_г Москва, проезд Строительный, вл 5
196	27905_г Москва, проезд 1-й Силикатный, вл 14
197	27906_г Москва, 17-й проезд Марьиной Рощи, вл 11
198	27907_г Москва, ул Маршала Чуйкова, ЗУ 047700394 в составе уч.4869 перечня ЗУ существующей УДС От границы с ЗУ 047700069 (Волгоградский просп.) до границы с ЗУ 047700436 (Юных Ленинцев ул.)
199	27912_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Алексеевский, проезд Мытищинский, земельный участок 10
200	27913_г. Москва, г. Зеленоград, улица Радио, дом 3, строения 1-8
201	27914_г. Москва, Походный проезд, вл. 1
202	27917_г Москва, г Зеленоград, Восточно-коммунальная Зона
203	27921_г. Москва, ул. Гурьянова (берег реки Москвы), сооружение 1
204	27922_г Москва, проезд Завода Серп и Молот, вл 4
205	27923_г Москва, г Зеленоград Северная Промзона, г Зеленоград, пр-кт Панфиловский, вл 8, Строение 2, 3
206	27924_г. Москва, г. Зеленоград, 1-й Западный пр-д, влд. 12, стр. 12
207	27925_г. Москва, 1-й Митинский пер., вл. 12, корп. 2 (рядом)
208	27927_г Москва, ул Газгольдерная, вл 6А
211	27929_г. Москва, ул. 60-летия Октября, вл. 11А
114	27943_Российская Федерация, г. Москва, вн.тер.г. пос. Десеновское, кв-л 145, зу 3
188	27947_Российская Федерация, город Москва, вн.тер.г. поселение Московский, квартал 45, земельный участок 26
209	27950_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Хорошево-Мневники, линия 2-я Хорошёвского Серебряного Бора, земельный участок 127
210	27951_г. Москва, поселение Внуковское, в районе д. Изварино
212	27953_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Хамовники, улица Россолимо, земельный участок 17
368	27954_город Москва, вн.тер.г. поселение Филимонковское, деревня Марьино, земельный участок 7/1, вблизи земельного участка с кадастровым номером 50:21:0150105:84
369	27955_г. Москва, ул. Вагоноремонтная, вл. 10А, стр. 18
370	27956_г. Москва, Дмитровское ш., вл. 9, стр. 3, 4
527	27956_город Москва, вн.тер.г. поселение Рязановское, деревня Мостовское, вблизи з/у Владение 49 с к.н. 50:27:0020418:136
371	27957_Российская Федерация, город Москва, вн.тер.г. поселение Михайлово-Ярцевское, квартал 130, з/у 1
372	27958_г. Москва, шоссе Ленинградское, земельный участок 338 (рядом)
373	27959_Российская Федерация, город Москва, ул. Новодачная, вл. 63 А (рядом с земельным участком с кадастровым номером 77:02:0025015:1100)
528	27962_Москва, ул Пермская, вл 11/11
374	27968_г Москва, ул Лобачевского, д 126
529	27970_г Москва, ш Очаковское, вл 2А
375	27970_г. Москва, 1-й Сетуньский проезд, вл. 1
376	27971_г Москва, пр-кт Мира, вл 98 Б
530	27971_г. Москва, ул. 1-я Стекольная, вл. 7, корп. 7
531	27972_г. Москва, ул. Рябиновая, вл. 45-А около
377	27972_Москва, ул Лыткаринская, вл 8
532	27973_адресные ориентиры: Дополнительный участок Октябрьской железной дороги №2, г. Москва
533	27974_г Москва, ул 3-я Хорошевская, вл 17, корпус 1
378	27974_город Москва, Лыткаринская улица, дом 15б
379	27975_(Российская Федерация, город Москва, внутригородская территория муниципальный округ Люблино, улица Верхние Поля)
534	27976_г Москва, Голубинская улица, вл 5, корп 1 и вл 5, корп 1, стр 2
380	27976_г. Москва, с. Троице-Лыково, ул. 1-я Лыковская, зу 105 (рядом)
535	27979_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Раменки, шоссе Воробьёвское, земельный участок 2А
536	27982_г Москва, ул 2-я Хуторская, вл 38А, стр 27, стр 28
381	27983_г Москва, ул Максимова, ЗУ 087700620 в составе уч.870 перечня ЗУ существующей УДС от границы с ЗУ 087700323 (Жадова Генерала пл.) до границы с ЗУ 087700037 (Берзарина ул.)
537	27983_г. Москва, п. Московский, д. Лапшинка, зу 113
382	27986_Российская Федерация, город Москва, вн.тер.г. поселение Внуковское, деревня Ликова, земельный участок 46В1
383	27987_г. Москва, ул. Дербеневская, вл.7
384	27991_28003_г Москва, ш Карачаровское, вл 8
538	27991_г Москва, ул Сущевский Вал, вл 5, стр 14
385	27992_г. Москва, Тарный проезд, вл. 13
539	27992_г. Москва, ул. Рябиновая, вл. 61А
386	27993_г. Москва, ул. Михневская, вл. 1 77050010004242
540	27993_Российская Федерация, город Москва, внутригородская территория муниципальный округ Молжаниновский, Ленинградское шоссе, земельный участок 302
541	27994_г Москва, ул Плещеева, вл 6
387	27994_г. Москва, ул. Попутная, вл. 1А
723	28058_г. Москва, ул. Новобутовская, з/у 8Б, напротив
388	27995_город Москва, вн.тер.г. поселение Щаповское, деревня Песье, земельный участок 3Б, вблизи з.у с кад. № 50:27:0020211:220
389	27998_адресные ориентиры: Татаровская пойма, ул. Крылатская
542	27998_г Москва, ул Академика Волгина, вл 21
543	28000_ул. Пермская, вл. 7 около
390	28001_г Москва, ул Молодогвардейская, вл 59
391	28002_город Москва, вн.тер.г. поселение Михайлово-Ярцевское, деревня Пудово-Сипягино, земельный участок Владение 2Б, вблизи земельного участка с кадастровым номером 50:27:0030148:30
544	28003_г Москва, ул Кольская, вл 12
545	28004_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Донской, улица Шаболовка, земельный участок 3111
546	28007_28008_город Москва, вн.тер.г. поселение Щаповское, деревня Песье, земельный участок 18, вблизи з.у с кад. № 77:22:0020211:299
392	28007_г Москва, проезд Каширский, вл 15
393	28008_г Москва, ул Люблинская, вл 68
394	28009_Российская Федерация, город Москва, вн.тер.г. поселение Вороновское, деревня Сахарово, земельный участок 49
395	28010_г. Москва, ул. Староорловская, напротив вл.105
547	28012_г. Москва, внутригородское муниципальное образование Бирюлево Восточное, Загорьевский проезд, вл. 17, корп. 1 (напротив)
548	28013_г. Москва , ул. 3-я Хорошевская, вл. 16 (рядом)
396	28014_28027_АДРЕСНЫЕ ОРИЕНТИРЫ: Г.ЗЕЛЕНОГРАД, ПРОМЗОНА МАЛИНО
549	28015_Российская Федерация, г. Москва, вн.тер.г. поселение Вороновское, кв-л 882, зу 33А
550	28016_Российская Федерация, г. Москва, вн.тер.г. пос. Краснопахорское, кв-л 217
397	28017_г. Москва, Староорловская, рядом с вл. 39А
551	28018_Российская Федерация, город Москва, вн.тер.г. поселение Марушкинское, деревня Крёкшино, улица Производственная, земельный участок 4А1
398	28018_Российская Федерация, город Москва, внутригородская территория муниципальный округ Ново-Переделкино, Староорловская улица, земельный участок 105Б
552	28019_г. Москва, Дмитровское шоссе, земельный участок 163Ж/1 (рядом)
553	28020_г Москва, ул Госпитальный Вал, вл 4
399	28023_г Москва, Ясный проезд, вл 26, корпус 2
554	28024_г. Москва, ул. Авиамоторная, земельный участок 19А9 (смежный)
400	28025_г. Москва, п. Десеновское, квартал 155, вблизи з/у с к/н 77:17:0140222:1388
401	28026_г. Москва, г. Троицк, ул. Институтская, рядом с кад. № 5054002031711
555	28027_г. Москва, проезд 1-й Тушинский, вл. 25
402	28029_ЖИЛОЙ МИКРОРАЙОН 1А КУРКИНО
556	28030_г. Москва, пос. Сосенское, Калужское ш., 21-й км, влд. 3В
403	28030_город Москва, поселение Щаповское, пос. Щапово
557	28032_Российская Федерация, город Москва, вн.тер.г. поселение Московский, деревня Саларьево, улица 1-я Новая, земельный участок 2А
404	28033_г. Москва, пер. Юрьевский, вл. 15 (смежный)
694	28036_г Москва, проезд Строительный, вл 2
740	28036_г Москва, ул Родниковая, вл 26, вблизи зу с кад. № 77:07:0015009:105
664	28036_г. Москва, 3-я Северная линия, вл. 1
759	28036_г. Москва, ш. Коровинское, вл. 41А, корп.2 рядом
558	28036_город Москва, поселение Марушкинское, д. Марушкино
681	28037_г Москва, пр-кт Вернадского, вл 89
720	28037_г Москва, проезд Чермянский, вл 7
741	28037_г Москва, ул Родниковая, вл 18
665	28037_город Москва, поселение Вороновское, вблизи д. Безобразово
559	28037_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Бирюлево Восточное, улица 3-я Радиальная, земельный участок 4А
695	28038_г Москва, ш Можайское, вл 10
742	28038_г. Москва, пос. Московский, деревня Мешково, улица Сосновая, вблизи зу с кад. № 50:21:0110113:1013
705	28038_г. Москва, район Тропарево-Никулино
760	28038_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Восточное Измайлово, улица 16-я Парковая, земельный участок 2Б
706	28039_г. Москва, Цветочный пр., вл. 7
761	28039_Москва, ул Шоссейная, вл 42, строен б/н
560	28039_ул Харьковская
762	28040_г Москва, проезд Чермянский, вл 14
666	28040_г Москва, ул Киевская, вл 14
743	28040_г Москва, ул Рабочая, вл 93, стр 3, 4
721	28040_г. Москва, ул. Промышленная, вл. 3 рядом
653	28040_город Москва, вн.тер.г. поселение Десеновское, улица Киселевская, вблизи земельного участка с кадастровым номером 77:17:0140222:274
707	28040_Российская Федерация, город Москва, внутригородская территория муниципальный округ Бабушкинский, Кольская улица, земельный участок 18А/1
708	28041_г Москва, Молодогвардейская улица, вл 61, корпус 2
682	28041_г. Москва, ул. Красковская, вл. 122 (рядом)\n\n 28057_г Москва, ул Красковская, ЗУ 03/77/00215 В СОСТАВЕ УЧ.5223 ПЕРЕЧНЯ ЗУ СУЩЕСТВУЮЩЕЙ УДС ОТ ГРАНИЦЫ С ЗУ 03/77/ПРОЕК (ПРОЕКТИРУЕМЫЙ ПРОЕЗД № 595) ДО ГРАНИЦЫ С ЗУ 03/77/00214 (КРАСКОВСКАЯ УЛ.), СОВПАДАЮЩЕЙ С КАД.ГРАНИЦЕЙ (С КВ.77:03:10008), ПРОХОДЯЩЕЙ ПО ОСИ КРАСКОВСКАЯ УЛ.
744	28042_г Москва, проезд Походный, вл 18-20
722	28042_г Москва, ул 1-я Тверская-Ямская, вл 27, стр 5
709	28042_г Москва, ул Докукина, вл 10, стр 11
696	28042_Киевское направление железной дороги участок № 4 (ЗАО), около
763	28042_Российская Федерация, город Москва, вн.тер.г. поселение Первомайское, деревня Клоково, бульвар Певчий, земельный участок 3/1
683	28043_г Москва, ул 2-я Карачаровская, вл 6/16
667	28043_г Москва, ш Ленинградское, ЗУ 09/77/00256
764	28043_г. Москва, Волоцкой переулок, вл. 15 (напротив)
697	28043_г. Москва, пос. Московский, д. Мешково, ул. Рябиновая (вблизи з.у. с кад. № 50:21:0110113:709)
745	28043_г. Москва, ЮВАО, район Некрасовка, ул. 2-я Вольская, земельный участок 17/4 (рядом)
654	28044_28045_28058_28059_ул. Южнопортовая, вл. 19А (смежный)
684	28044_г Москва, ул Академика Скрябина, вл 21
668	28044_г Москва, ул Зорге, вл 17А
724	28044_г Москва, ул Мусоргского, вл 3
765	28044_г Москва, ул Новоостаповская, вл 1, стр 1
746	28044_г Москва, ул Радиальная 6-я, вл 24, стр 9; 77:05:0010001:45 (рядом)
698	28044_г Москва, ул Сущевский Вал, вл 5, стр 15
710	28044_г. Москва, ул. Левобережная, вл. 32А
725	28045_г Москва, 1-й переулок Тружеников, вл 14, стр 5-5Б
685	28045_г. Москва, ул. Боженко, вл. 5Г, стр. 1, 2
699	28045_город Москва, вн.тер.г. поселение Десеновское, деревня Десна, улица Широкая, вблизи з.у. с к.н. 50:21:0140106:72
766	28045_город Москва, поселение Сосенское, в районе Николо-Хованского кладбища, уч-316ю
671	28046_г Москва, ул Нижняя, вл 14
726	28046_г Москва, ул Южнопортовая, вл 15
655	28046_г. Москва, п. Щаповское, д. Песье, уч. Владение 9, вблизи з.у с кад. № 50:27:0020211:251
686	28046_г. Москва, улица Сущёвский Вал
767	28046_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Матушкино, город ЗелАО, проспект Генерала Алексеева, земельный участок 7
747	28046_Российская Федерация, город Москва, вн.тер.г. поселение Десеновское, квартал 145, земельный участок 3
748	28047_28051_Российская Федерация, город Москва, вн.тер.г. поселение Десеновское, ул. 2-я Ватутинская, з/у 2
672	28047_г Москва, ул Вавилова, вл 91, корпус 2
711	28047_г Москва, ул Сельскохозяйственная, вл 62-А
656	28047_г Москва, улица Стромынка, вл. 18
768	28047_г. Москва, Строительный проезд, вл. 3А, стр. 1
727	28047_Москва, ул ШОССЕЙНАЯ, Дом 4А
687	28047_Российская Федерация, город Москва, вн.тер.г. поселение Сосенское, деревня Сосенки, земельный участок 137
712	28048_г. Москва, ул. Авиамоторная, вл. 51 Б, стр. 1, 2 (смежный)
688	28048_г. Москва, ул. Пяловская, вл. 7
749	28048_город Москва, вн.тер.г. поселение Краснопахорское, поселок Красное, улица Первомайская, земельный участок 8/2, вблизи з.у с кад. № 50:27:0020203:303
728	28048_город Москва, поселение Московский, с/к "Содружество"-Дудкино, уч.№106
673	28048_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Лосиноостровский, улица Изумрудная, земельный участок 3/2
700	28049_28041_г Москва, Монтажная улица, вл 2 около
674	28049_г. Москва, Причальный пр., вл. 6, к. 1
713	28049_г. Москва, ул Очаковская Б., вл 40, строен 4
775	28049_г. Москва, ул. Верхние Поля, вл. 51А
689	28049_Москва, ул Молостовых, Российская Федерация, внутригородская территория муниципальный округ Ивановское, земельный участок 1А
729	28049_Российская Федерация, город Москва, вн.тер.г. поселение Марушкинское, деревня Марушкино, проезд ЦАО, земельный участок 10Б
750	28049_Российская Федерация, город Москва, вн.тер.г. поселение Новофедоровское, поселок Рассудово, переулок 6-й Киевский, земельный участок 6
690	28050_АДРЕСНЫЕ ОРИЕНТИРЫ: ПРОМЗОНА "АЛАБУШЕВО"
714	28050_г Москва, проезд Лыковский, ЗУ 08/77/00375 в составе уч.1959 перечня ЗУ существующей УДС, От границы с ЗУ 08/77/00406 (МКАД (Северо-Запад 2)) до границы с ЗУ 08/77/00374 (Лыковский пр.), совпадающей с кад.границей (с кв.77:08:13008), проходящей по оси Лыковская 2-я ул.
675	28050_г Москва, ул Розанова, вл 10, стр 1
751	28050_г. Москва, Проектируемый проезд №3610, вл.10 (рядом)
701	28050_г. Москва, ул. Амурская, вл. 5 (рядом)
657	28050_город Москва, Молодогвардейская улица, между вл. 61 и вл. 63А
730	28050_Российская Федерация, город Москва, вн.тер.г. поселение Десеновское, улица Андерсена, земельный участок 2А
731	28051_г. Москва, Каширское шоссе, земельный участок 9Г/5
691	28051_г. Москва, поселение Десеновское, вблизи деревни Черепово
676	28051_Российская Федерация, город Москва, вн.тер.г. поселение Сосенское, деревня Николо-Хованское, земельный участок Владение 109Б
677	28052_28053_г. Москва, ул. Михельсона, вл. 3
752	28052_г Москва, пер Костомаровский, вл 3, стр 1
692	28052_г Москва, ул Академика Скрябина, вл 15, корпус 3
732	28052_г. Москва, 2-й Грайвороновский проезд, вл. 40А, стр. 1А, 6А
561	28052_г. Москва, Зеленоград, Проезд № 4921, дом 7, строения 1, 3, 4, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17
658	28052_город Москва, вн.тер.г. поселение Щаповское, деревня Песье, земельный участок 37
702	28052_Москва, ул Кубанская, вл 29, строен 1
693	28053_г Москва, ул Академика Скрябина, вл 19
733	28053_г. Москва, проезд Нансена, вл. 1
659	28053_г. Москва, Рязанский проспект, 26/9
753	28053_г. Москва, Ферганский проезд, вл. 1, стр. 2
562	28053_Москва, проезд Строительный, вл 7А, корп 17, 18, 30, 45А, 49
703	28053_Российская Федерация, город Москва, внутригородская территория муниципальный округ Орехово-Борисово Южное, Шипиловский проезд, земельный участок 22/5/1
776	28054_г Москва, пр-кт Мира, вл 98 Б
678	28054_г Москва, ул Лыткаринская, вл 2А
754	28054_г Москва, ул Малая Калужская, вл 15, стр 1, 17
734	28054_г. Москва, вн.тер.г. поселение Михайлово-Ярцевское, деревня Лужки, микрорайон Солнечный город-2, земельный участок 190, вблизи земельного участка с кадастровым номером 50:27:0030118:962
715	28054_г. Москва, ул. Образцова, вл. 7
563	28054_г. Москва, улица 2-я Железногорская, земельный участок 1
755	28055_г Москва, ул Летниковская, вл 8, стр 1
735	28055_г. Москва, ул. 3-я Рейсовая рядом с вл. 15/20
679	28055_г. Москва, ул. Златоустовская, вл. 52Г
777	28055_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Пресненский, переулок Большой Предтеченский, земельный участок 15/8/1
660	28055_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Рязанский, проезд 1-й Вешняковский, земельный участок 7
736	28056_г. Москва, ул. Гиляровского, вл. 5, стр. 1, 2
756	28056_г. Москва, ул. Зюзинская, вл. 6, корп. 2
778	28056_г. Москва, ул. Осенняя, вблизи вл. 23
661	28056_город Москва, вн.тер.г. поселение Щаповское, поселок Курилово, улица Урожайная, земельный участок 2/1
704	28056_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Хорошевский, улица 1-я Магистральная, земельный участок 8/2
716	28057_г Москва, Поклонная улица, дом 15
662	28057_г Москва, ул Авиамоторная, вл 48
680	28057_г. Москва, п. Назарьево, вл. 137, 28055_ вл. 125, 28056_рядом с вл. 127
779	28057_город Москва, вн.тер.г. поселение Внуковское, поселок Детского дома Молодая Гвардия, дом 2А, строение 2
737	28057_город Москва, поселение Сосенское, в районе Николо-Хованского кладбища (уточненный адресный ориентир: Московская область, Ленинский район, сельское поселение Сосенское, в районе Николо-Хованского кладбища, уч.№369ю вблизи з/у с к/н 50:21:0120230:789)
757	28057_Российская Федерация, город Москва, вн.тер.г. поселение Московский, квартал 45, земельный участок 26
717	28058_г Москва, ул Прянишникова, вл 19А
564	28058_г. Москва, промзона № 37 "Очаково", пр.пр. № 5320
738	28058_г. Москва, улица Шмидта, вл. 27, стр. 1 (около)
758	28059_г Москва, ул Вагоноремонтная, ЗУ 09/77/00045 в составе уч.367 перечня ЗУ существующей УДС От границы с ЗУ 09/77/ПРОЕК (Проектируемый проезд № 4943) до границы с ЗУ 09/77/00675 (МКАД (Север))
663	28059_г Москва, ш Ленинградское, вл 71, стр 2
718	28059_г. Москва, проезд Стройкомбината, около вл. 6, стр. 1
780	28059_г. Москва, сельское поселение Вороновское, д. Семенково, ул. Западная, з/у 6/2
739	28059_Москва, ул. Преображенский Вал, вл. 17 (вблизи)
565	28059_поселение Сосенское, поселок Коммунарка, улица Липовый парк, земельный участок Владение 1
781	28062_г Москва, ул Ставропольская, вл 84
566	28063_г Москва, ш Новосходненское, вл 4
782	28063_г. Москва, улица Шмидта, вл. 27, стр. 1 (около)
567	28064_город Москва, вн.тер.г. поселение Щаповское, деревня Песье, земельный участок 22/2
568	28065_г Москва, проезд Автомобильный, вл 10
783	28065_г. Москва, 2-й Южнопортовый проезд, вл. 10
784	28067_28079_28080_г. Москва, г. ЗелАО, п. Назарьево, рядом с вл. 131а
866	28072_г Москва, Высоковольтный проезд, вл 13а
785	28078_г. Москва, г. ЗелАО, Фирсановское шоссе
786	28081_г. Москва, проезд Походный, вл. 18-20 (рядом)
787	28085_г. Москва, г. ЗелАО, ул. Заводская рядом с д. 3
788	28087_2-й Дачно-Мещерский проезд, з/у 34 (около)
789	28092_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Южное Бутово, шоссе Варшавское, земельный участок 254А
790	28096_Российская Федерация, город Москва, вн.тер.г. поселение Щаповское, квартал 205, земельный участок 1В
791	28100_Российская Федерация, город Москва, вн.тер.г. поселение Марушкинское, деревня Шарапово, улица Карьерная, вблизи з/у 9Б с кад. № 77:18:0170403:36
792	28101_г Москва, Проектируемый проезд № 5113, дом 4
793	28102_город Москва, внутригородская территория поселение Новофедоровское, деревня Ожигово, улица Нагорная (вблизи земельного участка с кадастровым номером 77:21:0140403:408)
794	28103_г Москва, ул Докукина, вл 10, стр 11
795	28104_г. Москва, Ленинградское ш., вл. 71Б
796	28109_г. Москва, ул. Третьего Интернационала, вл. 30
803	28114_г Москва, ш Ленинградское, вл 251
804	28115_Российская Федерация, город Москва, внутригородская территория муниципальный округ Косино-Ухтомский, улица Лыткаринская, земельный участок 9
805	28120_г. Москва, ул. Родниковая, около вл. 7
806	28121_г. Москва, ул. Василия Ботылёва, около з/у 90
807	28122_Российская Федерация, город Москва, вн.тер.г. поселение Марушкинское, деревня Крёкшино, улица Производственная, земельный участок 4В
808	28130_город Москва, вн.тер.г. муниципальный округ Бекасово, деревня Рассудово, улица Камышовая, земельный участок 1
809	28142_г Москва,1-я Вольская улица, поселок Некрасовка, вл 47, соор.1
810	28145_г. Москва, проезд Шипиловский, вл. 8 (рядом)
811	28152_г.Москва, 9-я Чоботовская аллея, рядом с вл. 2
814	28153_г Москва, ш Волоколамское, вл 65-Б
815	28157_г. Москва, улица Ермакова Роща, вл. 7б, стр. 1-10
816	28159_г Москва, ул 1-я Стекольная, вл 7, стр 8
817	28160_Российская Федерация, город Москва, внутригородская территория муниципальныйокруг Дорогомилово, улица Киевская, земельный участок 19А
86	28167_г. Москва, поселение Московский, территория СНТ Верхнее Акатово, земельный участок 12
87	28169_Российская Федерация, город Москва, вн. тер. г. муниципальный округ Пресненский, улица2-я Звенигородская
867	28178_г Москва,1-я Вольская улица, поселок Некрасовка, вл 47, соор.1
88	28182_г Москва, пер 1-й Щипковский, вл 20
89	28186_г. Москва, ул. Харьковская, вл. 3А
868	28188_г. Москва, поселение Марушкинское, поселение Первомайское, между д. Шарапово, д. Давыдково, пос. Кирпичного завода, д. Кривошеино, д. Соколово, д. Ивановское, д. Настасьино, пос. Красные горки, д. Анкудиново
90	28190_г. Москва, ул. 1-я Новые Сады, вл. 1А рядом
869	28196_г. Москва, ул. Осенняя, вблизи вл. 25А
870	28197_г Москва, проезд Нагорный, вл 12В, стр 8, 9, 11
91	28210_г Москва, проезд Строительный, д 6
820	28549_г. Москва, ул. Люблинская, вл. 18А
92	28211_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Краснопахорский, квартал 64, земельный участок 29
93	28212_г. Москва, улица Марксистская, земельный участок 34/7
94	28214_г. Москва, г. Зеленоград, п. Назарьево, вл. 127, 135, 137 и рядом с вл. 119А/1 (77:10:0005007:1400)
95	28219_поселение Роговское, поселок Рогово, улица Заречная, земельный участок 89А
96	28221_г. Москва, парк "Березовая роща"
871	28222_г. Москва, ул. Маршала Конева, вл. 6 (рядом)
97	28223_г. Москва, ул. Салтыковская, вл. 6
872	28224_г Москва, 5-я ул Соколиной Горы
873	28226_город Москва, вн.тер.г. поселение Первомайское, квартал 295, вблизи земельного участка 15 с кадастровым номером 50:26:0190402:89
98	28227_г. Москва, ул. Перерва, вл. 88
874	28228_г. Москва, ул. Дорожная, вл. 3, корп. 19; вл. 3, корп. 19, стр. 1, 3-7
99	28229_Российская Федерация, город Москва, внутригородская территория (внутригородское муниципальное образование) города федерального значения муниципальный округ Лефортово, улица Самокатная
875	28230_г. Москва, ул. Дербеневская, вл.7
100	28231_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Летово, улица Летовская, земельный участок 2/1
876	28233_г. Москва, г. ЗелАО, Восточная коммунальная зона (пересечение улицы Сосновая аллея с проектируемым проездом 5526)
101	28233_г. Москва, г. Зеленоград, Восточная коммунальная зона (пересечение улицы Сосновая аллея с проектируемым проездом 5526)
102	28234_АДРЕСНЫЕ ОРИЕНТИРЫ: ПРОЕКТИРУЕМЫЙ ПРОЕЗД №3769 В РАЙОНЕ ПЛАТФОРМЫ "МАТВЕЕВСКАЯ"
103	28235_город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Губкино, улица Кронбургская, земельный участок 1Б
104	28236_г. Москва, ул. Михельсона, вл. 54/2
877	28236_г. Москва, ул. Михельсона, вл. 542
105	28239_г Москва, ул Шоссейная, вл 90, стр 101
106	28240_г Москва, 1-й Пехотный пер, вл 10
879	28241_28242_г Москва, пер 1-й Котляковский, вл 2
107	28241_г Москва, пер 1-й Котляковский, вл 2
880	28244_обл. Московская, д. Грибки, дом 2
108	28248_г Москва, ул Перерва, вл 21А
881	28249_г. Москва, ул. Шоссейная, вл. 78А, стр. 1 (рядом)
882	28253_город Москва, поселение Московский, в районе дер. Лапшинка
452	28255_г Москва, ул Мартеновская, вл 33
453	28256_Российская Федерация, г. Москва, ул. Нагатинская
454	28257_28324_г Москва, ул Докукина, вл 10, стр 11
455	28261_г Москва, 3-я Магистральная улица, ЗУ 09/77/00649 в составе уч.2356 перечня ЗУ существующей УДС От дома № 8а до границы с ЗУ 09/77/00648 (Магистральная 3-я ул.), совпадающей с кад.границей (с кв.77:09:05010), проходящей по съезду на мост через ж/дорогу
456	28262_г. Москва, ул. Братеевская, вл. 39/12 (рядом)
457	28263_г Москва, ул 4-я Магистральная, вл 5, стр 3, 4, 13
458	28264_г. Москва, 2-я Лыковская ул., з/у 16
459	28266_г. Москва, между ул. Митинская и ул. Пинягинская (Ландшафтный парк Митино) (рядом)
460	28273_г Москва, ул Совхозная, вл 1
461	28274_г. Москва, 2-ой Вязовский проезд, вл. 10, стр. 1, 2, 3, 4, 5
462	28275_г. Москва, Дмитровское шоссе, вл. 9 и вл. 9, стр. 2
463	28276_г. Москва, территория Природно-исторического парка "Москворецкий", СЗАО г. Москвы
464	28277_город Москва, поселение Щаповское, д. Овечкино
465	28280_г. Москва, Ленинградское шоссе, рядом с вл. 266
466	28281_28282_28462_28463_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Перово, улица 2-я Энтузиастов, земельный участок 5/17А
467	28285_г Москва, 7-я Кожуховская улица, вл 52А
468	28286_Российская Федерация, город Москва, вн. тер. г. муниципальный округ Пресненский, улица2-я Звенигородская
469	28289_г Москва, ул Полбина, дом 15 (рядом)
470	28290_г. Москва, ул. Чермянская, вл. 6
471	28294_г. Москва, ул. Фрязевская, вл. 8А (рядом)
472	28296_г. Москва, Черницынский пр., вл. 3, стр. 1
473	28299_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Преображенское, улица Малая Семёновская, земельный участок 11/2/16
474	28301_г Москва, ул Арбат, вл 4, стр 1
995	28668_Москва, ул Ижорская, Промзона №46, "Коровино", з/у 1
475	28302_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, квартал 179, земельный участок 49
476	28303_г. Москва, ул. Талдомская, вл. 2Д, стр. 2
477	28307_г. Москва, Холодильный переулок, вл. 3, вл. 3, стр. 8, 9, 10
478	28308_г Москва, ул Электрозаводская, вл 21
479	28316_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Некрасовка, ул. 2-я Вольская, з/у 30/2А
480	28317_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Краснопахорский, поселок Шишкин Лес, земельный участок 44А
481	28318_г Москва, ул Мосфильмовская, вл 80А
482	28321_г. Москва, поселение Сосенское, пос. Коммунарка, СНТ "Гавриково"
483	28322_Москва, ул Лыковская 2-я, вл 61/1
484	28325_г Москва, шоссе МКАД (Восток), ЗУ 03/77/00760 в составе уч.4011 перечня ЗУ существующей УДС, От границы с ЗУ 03/77/00754 (МКАД (Восток)), совпадающей с кад.границей (с кв.77:03:06028), проходящей по юго-восточной границе полосы отвода МЖД Горьковского направления до границы с ЗУ 03/77/00757 (МКАД (Восток)), совпадающей с кад.границей (с кв.77:03:07005), проходящей по оси пешеходного прохода между гаражами к МКАД
485	28326_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Косино-Ухтомский, улица Камова, земельный участок 15
486	28327_г Москва, пр-кт Зеленый, вл 20
487	28328_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Внуково, деревня Большое Свинорье, проезд Черничный, земельный участок 72
488	28329_г. Москва, Варшавское шоссе, вл. 28
489	28333_г. Москва, ул. Дорожная, вл. 3, корп. 2
283	28338_адресные ориентиры: ИЖОРСКАЯ УЛ.,ПРОМЗОНА N46 ,"КОРОВИНО"
284	28339_г. Москва, ул. Маршала Прошлякова, з/у 12А
285	28341_Российская Федерация, город Москва, вн.тер.г. городской округ Троицк, квартал 145А, земельный участок 3
286	28343_г. Москва, ул. Дорожная, вл. 3, корп. 19; вл. 3, корп. 19, стр. 1, 3-7
287	28344_г Москва, проезд Полярный, ЗУ 027700483 в составе уч.529 перечня ЗУ существующей УДС От границы с ЗУ 027700484 (Полярный пр.), совпадающей с кад.границей (с кв770205005), проходящей по оси Чермянская ул. до границы с ЗУ 027701155 (Широкая ул.)
288	28345_город Москва, вн.тер.г. муниципальный округ Бекасово, поселок Рассудово, переулок 6-й Киевский, земельный участок 6
289	28352_г. Москва, ш. Энтузиастов, вл. 56/57 (рядом)
290	28353_обл. Московская, д. Грибки, дом 2
291	28355_улица Самокатная, земельный участок 4/40
292	28356_г Москва, б-р Бескудниковский, вл 20-А
293	28361_деревня Внуково, улица Игоря Ильинского, земельный участок 15
294	28362_г Москва, ул Малая Бронная, вл 2/7, стр 1
295	28363_город Москва, вн.тер.г. поселение Внуковское, деревня Ликова, 46В1
296	28364_г Москва, наб Шлюзовая, вл 2/1
297	28366_г.Москва, ул. Староорловская, рядом с вл. 106
298	28373_ г. Москва, ул. Перовская, вл. 1
418	28374_г Москва, ул Академика Челомея, вл 5А
299	28375_г. Москва, кв-л Капотня 2-й, вл. 1, сооружение 1, стр. 77, 78, 79 (рядом)
300	28376_г Москва, ул Мосфильмовская, вл 80А
301	28377_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Пресненский, улица 1905 года, земельный участок 10А/1
302	28378_г. Москва, пр-д Мытищинский, вл. 22 (около)
303	28384_г Москва, наб Лихоборская, ЗУ 09/77/00274 в составе уч.1020 перечня ЗУ существующей УДС От границы с ЗУ 09/77/00270 (Лихоборская наб.), проходящей вблизи Проектируемый проезд № 1499 до границы с ЗУ 09/77/00273 (Лихоборская наб.), совпадающей с кад.границей (с кв.77:09:01030), проходящей по юго-западной границе полосы отвода ОЖД
304	28386_город Москва, п. Первомайское, ЗАО "Первомайское", под водными объектами
305	28387_г. Москва, ул. Чермянская, вл. 4
306	28388_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Щербинка, поселок Знамя Октября, земельный участок 56А
307	28391_г Москва, ул Большая Очаковская, вл 47А
308	28392_г. Москва, Походный пр-д, вл. 3А, стр. 1 (рядом)
309	28394_г Москва, ул Полбина, дом 15
310	28397_г Москва, ш Новосходненское, вл 4
311	28398_г Москва, ул Южнопортовая, вл 5
312	28401_г. Москва, ТПУ «Николаевская»
313	28402_г. Москва, ул. Зорге, вл. 15
590	г. Москва, ул. Деловая, д. 20
314	28403_город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Сосенки, улица Ольховая, вблизи земельного участка 10/1 с кадастровым номером 50:21:0120114:1667
315	28405_город Москва, поселение "Мосрентген", д. Дудкино, уч.№30а
316	28407_г. Москва, вн.тер.г. муниципальный округ Филимонковский, поселок Марьино, бульвар Светлый, земельный участок 18Б вблизи участка с кад. № 77:17:0150111:2448
317	28410_г. Москва, ул. 3-я Музейная, вл. 44, стр. 1
318	28411_г Москва, ул Вавилова, вл 9А, стр 3, 11, 19, 20
319	28412_г. Москва, улица Вавилова, вл. 9А, стр. 3,11,19, 20
320	28416_г Москва, ул Рябиновая, вл 32
623	28418_28419_город Москва, вн.тер.г поселение Рязановское, деревня Ерино, улица Центральная
624	28422_28423_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Губкино, земельный участок 78
625	28424_Российская Федерация, город Москва, вн.тер.г. поселение Филимонковское, квартал 173, земельный участок 55/1
626	28427_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Краснопахорский, квартал 64, земельный участок 29
627	28428_Российская Федерация, город Москва, вн.тер.г. городской округ Троицк, квартал 84, земельный участок 189А/2А
628	28429_г. Москва, СНТ "Мир"
629	28430_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Молжаниновский, шоссе Ленинградское, земельный участок 266
630	28431_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Вороново, квартал 415, земельный участок 40
631	28432_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Солнцево, квартал 32, земельный участок 17Б/3
632	28433_г. Москва, ул. Лыковская 2-я, земельный участок 65/32
633	28435_г. Москва, Перовский проезд, вл. 54, стр. 10, 11
634	28439_Внуково, улица 2-я Рейсовая, земельный участок 14/1
635	28441_АДРЕСНЫЕ ОРИЕНТИРЫ: Г. ЗЕЛЕНОГРАД, ПРОЕЗД 4802
636	28445_г. Москва, Варшавское шоссе, вл. 28
622	28447_г. Москва, ул. Перовская, вл. 1, стр. 22
620	28450_28451_г. Москва, г. Зеленоград, п. Назарьево, вл. 101, вл. 97
637	28453_28464_Москва, проезд Игарский, вл 11
638	28455_АДРЕСНЫЕ ОРИЕНТИРЫ: ПРОМЗОНА ЧАГИНО, ПР. ПР.4586, Д. 4
639	28459_28038_г Москва, ул Милашенкова, вл 6А
640	28465_28037_г Москва, ул Талалихина, вл 41, зу 33/3
641	28467_г Москва, Анненский проезд, дом 2a
642	28470_г. Москва, ул. Летниковская, вл. 11/10, стр. 26
643	28472_г Москва, ш Ленинградское, вл 261
621	28473_28474_г. Москва, улица Вавилова, вл. 9А, стр. 3,11,19, 20
644	28476_г Москва, ул Сельскохозяйственная, вл 62-А
645	28478_г. Москва, ул. Обручева, вл. 16, корп. 1, рядом
646	28491_г Москва, ул Мытищинская 1-я, вл 21
647	28493_г. Москва, ул. Верхние поля, вл. 22, с.1
648	28494_г Москва, ул Осенняя, вл 15
649	28497_28507_г Москва, проезд Научный, вл 11А
619	28501_28438_г. Москва, ул. Гатчинская, рядом с з/у 25
650	28502_г Москва, Волгоградский проспект
651	28504_г Москва, ул Промышленная, вл 11
652	28506_г. Москва, ш. Рублевское
823	28508_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Николо-Хованское, земельный участок 110
824	28510_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Кунцево, улица 5-я Мякининская, земельный участок 16
825	28513_Российская Федерация, г. Москва, п. Внуковское, д. Рассказовка, з/у 18/1
826	28515_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Внуково, поселок дск Мичуринец, улица Довженко, земельный участок 11
827	28517_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Вороново, деревня Голохвастово, земельный участок 8А
828	28535_Российская Федерация, город Москва, внутригородская территория муниципальныйокруг Некрасовка, улица 1-я Вольская, земельный участок 39
865	28538_город Москва, внутригородская территория муниципальный округ Котловка, проспект Нахимовский, земельный участок 8/2
829	28539_28540_28541_28542_г Москва, ул Профсоюзная, вл 128, корпус 2
849	28547_на пересечении Новоясеневского проспекта с Профсоюзной улицей
850	28548_г. Москва, проезд 607, вл. 26, корп. 3
851	28550_город Москва, вн.тер.г. муниципальный округ Вороново, деревня Никоново
852	28554_г Москва, ул 2-я Хуторская, вл 38А
853	28555_г Москва, ул Радиальная 6-я, вл 62
854	28556_г Москва, ул Осенняя, вл 15
855	28557_г. Москва, ул. Хачатуряна (техзона)
856	28563_г. Москва, ул. Маршала Воробьева, вл. 12, корп. 3
819	28566_Российская Федерация, город Москва, вн.тер.г. поселение Сосенское, поселок Коммунарка, улица Александры Монаховой, земельный участок 55А
818	28568_Российская Федерация, город Москва, внутригородская территория муниципальный округ Северное Медведково, Чермянский проезд, земельный участок 4/2
821	28569_г Москва, проезд 2-й Иртышский
857	28571_28572_28573_г.Москва, ул.Южнопортовая, вл.21
858	28574_адресные ориентиры: Южное Бутово, ул. Поляны, коммунальная зона "Гавриково"
859	28575_г. Москва, г Щербинка, местечко Барыши
860	28576_г Москва, ул Кибальчича, вл 5, стр 1, 2
861	28578_город Москва, поселение Сосенское, ориентир в районе Николо-Хованского кладбища
862	28583_город Москва, вн.тер.г. муниципальный округ Внуково, квартал 97, земельный участок 17 вблизи
863	28589_Российская Федерация, город Москва, вн.тер.г. городской округ Троицк, деревня Жуковка, улица Вишнёвая, земельный участок 80
864	28592_Российская Федерация, город Москва, внутригородская территория городской округ Троицк, город Троицк, улица Высотная, земельный участок 1/1
942	28594_г. Москва, улица Сущёвский Вал
943	28595_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Вороново, квартал 830, земельный участок 3Б
944	28596_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Филимонковский, поселок Первомайское, улица Рабочая, вблизи з/у 19 с кад. № 50:26:0190402:9
945	28597_г Москва, ул Рябиновая, вл 32
946	28598_город Москва, поселение Роговское, п. Рогово
947	28599_город Москва, вн.тер.г. муниципальный округ Вороново, поселок Рогово, улица Заречная
948	28602_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Вороново, деревня Горнево
949	28603_г Москва, платф Северянин, вл 2
950	28605_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Вороново, деревня Жохово
951	28608_г. Москва, ул. Нижние Поля, вл. 37 (смежный)
952	28609_г Москва, проезд № 3502
953	28610_город Москва, вн.тер.г. муниципальный округ Коммунарка, поселок завода Мосрентген, проезд Институтский, земельный участок 7А
954	28613_город Москва, вн.тер.г. муниципальный округ Печатники, улица Угрешская, земельный участок 18/1/25
955	28614_г. Москва, ул. Оранжерейная, вл. 25А (рядом)
956	28615_г Москва, ул Новохохловская, вл 11
957	28617_г Москва, проезд Нововладыкинский, вл 6
958	28618_город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Губкино, земельный участок 78
959	28619_г Москва, ул Сормовская, вл 16
960	28622_г. Москва, ул. Садовники, вл. 11, корп.2А
961	28623_г. Москва, ул. Ижорская
962	28626_г. Москва, ул. Исаковского, вл. 4 (вблизи)
963	28629_г. Москва, ул. Донецкая, вл. 30 (смежный)
964	28630_г. Москва, улица Новая, земельный участок 1А
965	28631_муниципальный округ Басманный, переулок Переведеновский, земельный участок 219
966	28632_г. Москва, Хорошёвское шоссе, вл. 43
967	28633_г Москва, ул Верхние поля, вл 33
968	28639_г.Москва, ул.Южнопортовая, вл.21
969	28641_Покровское-Стрешнево, шоссе Ленинградское, земельный участок 23
970	28642_г. Москва, МЖД, Киевское, 5-й км, вл. 9
971	28645_г. Москва, проезд Павелецкий 2-й, д. 12А
972	28647_г. Москва, ул. Складочная, вл. 15, стр. 1, 2
973	28648_г. Москва, ул. Зорге, вл. 9 (около)
974	28649_г. Москва, ул. Кольская, вл. 14
975	28653_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Внуково, деревня Внуково, улица Игоря Ильинского
976	28654_г Москва, ул Генерала Белобородова, вл 46
977	28655_г Москва, туп Сходненский, вл 16
978	28657_г. Москва, ул. Образцова, влд. 19, к. 2
979	28659_г. Москва, ул. Южнопортовая, вл. 25Б
996	28671_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Краснопахорский, поселок подсобного хозяйства Минзаг, улица Солнечная, земельный участок 18/1
997	28672_г. Москва, малое кольцо Московской окружной железной дороги САО (участок №10)
998	28673_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, квартал 11, земельный участок 159
999	28675_г. Москва, ул.Поклонная, вл. 9
1000	28676_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Внуково, деревня Лапшинка, земельный участок 113
1001	28677_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Ямонтово, земельный участок 71/1
1002	28678_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Южное Тушино, улица Фабрициуса, земельный участок 19А
1003	28679_Российская Федерация, г. Москва, вн.тер.г. муниципальный округ Рязанский, проезд 2-й Вязовский, з/у 16
1004	28681_г Москва, проезд Проектируемый № 5112
1005	28683_Г. МОСКВА, ПРОМЗОНА ,ПР.ПР.5217
1006	28684_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Коммунарка, деревня Сосенки, земельный участок 127
1007	28685_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Измайлово, поселок Измайловская Пасека, земельный участок 1
1008	28688_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Лефортово, улица Самокатная, земельный участок 4/40
1009	28689_г. Москва, Западная ул., д 11
1010	28692_г. Москва, Электролитный проезд, вл. 3
1011	28693_Российская Федерация, город Москва, вн.тер.г. муниципальный округ Свиблово, проезд Серебрякова, земельный участок 8/8
1012	28694_г. Москва, ш. Куркинское, д. 68, стр. 1, уч. 9
1013	28697_г. Москва, Перовский проезд
1014	28702_Российская Федерация, город Москва, вн.тер.г. поселение Сосенское, поселок Коммунарка, улица Липовый парк
842	3-я Мытищинская ул., зу 16/59
844	5112-й Проектируемый пр-д , зу 7/2
1025	Адмирала Корнилова ул., зу 69/2
931	Бардина ул., зу 4/1
40	Басовская ул. , вл. 14, стр. 1, стр. 2
14	Берингов проезд, вл. 3, стр. 5
990	Болотниковская ул., зу 36Е/1
1015	Большая Косинская ул., д. 121
930	Большая Филевская ул., вл. 32-34
984	Ботаническая ул., зу 2
70	Ботаническая ул., зу 31/18
71	Ботаническая ул., зу 4/10
123	Ботаническая ул., зу 4/10_Часть 1
132	Ботаническая ул., зу 4/10_Часть 10
124	Ботаническая ул., зу 4/10_Часть 2
125	Ботаническая ул., зу 4/10_Часть 3
126	Ботаническая ул., зу 4/10_Часть 4
127	Ботаническая ул., зу 4/10_Часть 5
128	Ботаническая ул., зу 4/10_Часть 6
129	Ботаническая ул., зу 4/10_Часть 7
130	Ботаническая ул., зу 4/10_Часть 8
131	Ботаническая ул., зу 4/10_Часть 9
1023	в районе дер. Саларьево, 50:21:0110301:828
77	в районе Проектируемый проезд 4294-й, зу 4
4	в районе ул. Сочинская, зу 16/2
992	Варшавское ш., вл. 125Ж, корп. 5, 6, 7
981	Варшавское ш., дом 37А
51	вблизи вн.тер.г. поселение Вороновское, кв-л 142, з/у 8
932	Верхняя ул., зу 20/1
43	вн.тер.г. городской округ Троицк, город Троицк, улица Полковника милиции Курочкина, земельный участок 7
41	вн.тер.г. городской округ Троицк, город Троицк, улица Физическая, земельный участок 11/1
601	вн.тер.г. муниципальный округ Внуково, деревня Марушкино, улица Привольная, земельный участок 11
937	вн.тер.г. муниципальный округ Внуково, деревня Рассказовка, земельный участок 204
24	вн.тер.г. муниципальный округ Коммунарка, деревня Николо-Хованское, земельный участок 1007
28	вн.тер.г. муниципальный округ Краснопахорский, квартал 267, земельный участок 1А
15	вн.тер.г. муниципальный округ Краснопахорский, квартал 312, земельный участок 4
18	вн.тер.г. муниципальный округ Краснопахорский, поселок Армейский, земельный участок 11
603	г. Москва, ул. Дубнинская, д. 83А, стр.19
591	г. Москва, ул. Елецкая, д. 26
27	вн.тер.г. муниципальный округ Краснопахорский, поселок подсобного хозяйства Минзаг, улица Солнечная, земельный участок 20
939	вн.тер.г. муниципальный округ Солнцево, квартал 29, земельный участок 17Б/3
983	вн.тер.г. муниципальный округ Солнцево, квартал 32, земельный участок 17Г
20	вн.тер.г. муниципальный округ Щербинка, квартал 52, земельный участок 3
938	вн.тер.г. поселение Внуковское, квартал 30, земельный участок 6
30	вн.тер.г. поселение Десеновское, улица 1-я Ватутинская, земельный участок 3
812	вн.тер.г. поселение Московский, деревня Румянцево, улица Центральная, земельный участок 56А
615	вн.тер.г. поселение Московский, улица Татьянин Парк, земельный участок 16А
16	вн.тер.г. поселение Первомайское, квартал 425, земельный участок 1
23	вн.тер.г. поселение Сосенское, квартал 156, земельный участок 108В/1
44	внутригородская территория городской округ Троицк, город Троицк, улица Промышленная, земельный участок 6/1
12	внутригородская территория муниципальный округ Южное Бутово, Новобутовская улица, дом 13
46	внутригородская территория поселение Вороновское, поселок ЛМС, микрорайон Центральный, земельный участок 10Б
19	внутригородская территория поселение Краснопахорское, деревня Красная Пахра, земельный участок 141В
33	внутригородская территория поселение Краснопахорское, деревня Красная Пахра, земельный участок 55Ж
25	внутригородская территория поселение Щаповское, квартал 401, земельный участок 8А
1051	Восточный пгт, ул 9 Мая, вл 8, стр 1
573	г Москва, Очаковское шоссе, д 44
574	г Москва, ул Дорожная, д.1, корп.5, стр.5
919	г. Зеленоград, 4921-й проезд, зу 2/1
1076	г. Зеленоград, 4921-й проезд, зу 2/1
1069	г. Зеленоград, 5-й микрорайон
1070	г. Зеленоград, Крюково, 16-ый микрорайон
1071	г. Зеленоград, Назарьево
1085	г. Зеленоград, п. Назарьево
1072	г. Зеленоград, проезд № 4921, д. 1, стр. 1
797	г. Зеленоград, проспект Генерала Алексеева
1084	г. Зеленоград, проспект Генерала Алексеева
329	г. Москва , ул. Красная Сосна, вл. 30, д. 24, д. 24с1
845	г. Москва, 1-ый Иртышский пр-д., д. 3к19
581	г. Москва, 2-й Вязовский проезд, дом 10, стр. 2
925	г. Москва, 3-й Угрешский проезд, д. 14А, стр.3
575	г. Москва, 3-й Угрешский проезд, д. 6\nг. Москва, 3-й Угрешский проезд, д. 6, стр.1
576	г. Москва, Алтуфьевское шоссе, вл. 23
577	г. Москва, Алтуфьевское шоссе, д. 27А
571	г. Москва, вн.тер.г. поселение Вороновское, кв-л 858, з/у Владение 1
578	г. Москва, вн.тер.г. поселение Московский, кв-л 34, з/у 1
579	г. Москва, г. Зеленоград, проезд № 687, д. 2
580	г. Москва, г. Троицк, ул. Дальняя, д. 3
325	г. Москва, Дмитровское шоссе, д. 163, стр.5
799	г. Москва, Днепропетровский проезд, д. 4А, стр. 3а, стр. 6а, стр.6, стр 7
582	г. Москва, Загородное шоссе, д. 2В
596	г. Москва, Капотня 2-й квартал, вл. 1
597	г. Москва, Остаповский проезд, д. 6, стр.1, 12с7
598	г. Москва, Открытое шоссе, д. 12, стр.36
326	г. Москва, п. Восточный
1036	г. Москва, пос. Краснопахорское, с. Красная Пахра, Калужское шоссе, д.6
572	г. Москва, пос. Филимонковское, п. Марьино, ОАО Марьинская птицефабрика
600	г. Москва, поселение Рязановское, Рязановское шоссе, д. 4А, стр.6
569	г. Москва, пр-д 1-й Перова Поля, д. 10
583	г. Москва, проезд Ижорский, д. 11, стр.9
1038	г. Москва, Промзона «Бутово» пр. Проезд № 185, вл. 8, стр.5
584	г. Москва, Рязановское поселение, вблизи пос. Фабрики им. 1-го Мая
602	г. Москва, Тихорецкий бульвар, д.1, стр.20
585	г. Москва, ул. 2-ая Рыбинская, д. 13
586	г. Москва, ул. Бирюсинка, д. 5, стр.7\n г. Москва, ул. Иркутская, д. 3, стр.21
587	г. Москва, ул. Василия Петушкова, д. 3
588	г. Москва, ул. Генерала Дорохова, вл. 12 стр. 7\n ул. Генерала Дорохова, вл. 5, корп. 2\n г. Москва, ул. Генерала Дорохова, д. 10Г, стр.1
589	г. Москва, ул. Генерала Дорохова, д. 18, стр.3, стр. 4
604	г. Москва, ул. Ижорская, д. 5, стр. 1
605	г. Москва, ул. Илимская, д. 1
606	г. Москва, ул. Котляковская, д. 6А, стр.1
607	г. Москва, ул. Левобережная, вл. 6А
608	г. Москва, ул. Оренбургская, д. 32, вл. 1
609	г. Москва, ул. Плеханова, вл. 9
610	г. Москва, ул. Производственная, д. 23
611	г. Москва, ул. Реутовская, д. 7а
612	г. Москва, ул. Рябиновая, вл. 17А, стр.4
613	г. Москва, ул. Рябиновая, д. 28, стр. 1
614	г. Москва, ул. Салтыковская, д. 8, стр.21
1039	г. Москва, ул. Шоссейная, д. 90, стр. 62, стр. 72 левее
616	г. Москва, ш. Варшавское, д. 34А/1, 36А и левее
617	г. Москва, Ярославское шоссе, д. 2е
618	г. Троицк, Индустриальная ул.
592	г. Троицк, Калужское ш., зу 21А
1081	г. Троицк, Калужское ш., зу 21А
593	г. Троицк, Полковника милиции Курочкина ул., зу 7
594	г. Троицк, Промышленная ул., зу 11
282	г. Троицк, Промышленная ул., зу 6/1
362	г. Троицк, Физическая ул., зу 11/1
158	г. Щербинка, кв-л Южный, зу 13
355	город Москва, г. Троицк, 41 км Калужского шоссе
351	город Москва, поселение Вороновское, д. Ясенки
349	д. Марушкино, Октябрьская ул., зу 59Б
359	д. Яковлевское, площадь Торговая, зу 12/1
38	деревня Никульское
324	Дмитровское ш., уч. влд. 124А, з/у 3
331	Дорожная ул., зу 3/2
772	Западная ул., вл. 4, 77:03:0008001:6532
838	Западная ул., вл. 4, 77:03:0008001:67
73	Западная ул., зу 16/1
985	Зона между 1-м Курьяновским проездом, 2-я Курьяновская ул., 4-я Курьяновская ул. И Проектируемый пр-д № 4311
1047	Зона между 2-ой Вольный пер., Вольная ул., Окружной пр-д и 9-ая ул. Соколиной Горы
1049	Зона между Золотая ул., просп. Будённого и Семёновский пр-д
1050	Зона между МСД, ул. Маресьева, ул. Вертолётчиков и ул. Сочинская
1073	Зона между МСД, ул. Маресьева, ул. Вертолётчиков и ул. Сочинская
831	Зона между ул. Бирюсинка, 2-ой Иртышский пр-д, Черницынский пр-д и Амурская ул.
833	Зона между ш. Энтузиастов, ул. Плеханова, Перовская ул. и ЖД
834	Зона между Юго-Восточной хордой и улицами 2-я Курьяновская, 4-я Курьяновская и Батюнинская
922	Измайловский бульвар, вл 55/16-57
1061	Илимская ул., вл. 3/13
1062	Илимская, вл 3/13
836	Институтский пер., зу 2/П
835	Канатчиковский проезд
6	Капотня, 2-й квартал, вл. 1
1046	Каширское ш., вл. 15
1042	километр МЖД Киевское 5-й, земельный участок 5/6
1030	Косино-Ухтомский
980	Крылатская улица, вл. 1
1087	Крылатская улица, вл. 1
846	Ленинградское шоссе_1
1018	Ленинградское шоссе_2
1026	Ленинградское шоссе_3
570	Ленинградское шоссе_4
1024	Ленинский проспект, вл. 111, корп. 1
847	Липецкая ул., зу 5А/2_Ч. 1
65	Липецкая ул., зу 5А/2_Ч. 2
66	Липецкая ул., зу 5А/2_Ч. 3
67	Липецкая ул., зу 5А/2_Ч. 4
68	Липецкая ул., зу 5А/2_Ч. 5
1048	Липецкая ул., зу 5А/2_Ч. 6
137	Лыткаринская ул., вл. 2А
138	Маломосковская, вл. 22, стр. 4, 8
139	Мартеновская ул., вл. 33
140	между Вологодским пр., Алтуфьевским ш. и 84-м км МКАД (усадьба "Алтуфьево"
141	МО Внуково, д. Рассказовка, зу 204
142	МО Внуково, п. Толстопальцево, Центральная ул., зу 3/2
936	МО Внуково, хутор Брёхово, зу 90
26	МО Вороново, кв-л 86, зу 5
928	МО Коммунарка, д. Николо-Хованское, зу 1007
75	МО Коммунарка, д. Николо-Хованское, зу 1021
1088	МО Коммунарка, д. Николо-Хованское, зу 1021
146	МО Коммунарка, деревня Николо-Хованское, земельный участок 1007
1057	МО Коммунарка, деревня Саларьево, улица 1-я Новая, земельный участок 1А/3
356	МО Коммунарка, квартал 72, земельный участок 4
1056	МО Коммунарка, кв-л 115, зу 2А
341	МО Коммунарка, кв-л 196, зу 108В/1
841	МО Коммунарка, кв-л 74, зу 2, зу 2А
669	МО Коммунарка, кв-л 74, зу 2А
1032	МО Коммунарка, кв-л 74, зу 3, зу 3А
830	МО Коммунарка, Красулинская ул., зу 15
1021	МО Краснопахорский, д. Сенькино-Секерино, зу 1/2, 2/2
340	МО Краснопахорский, кв-л 171, зу 28
1035	МО Краснопахорский, кв-л 171, зу 40А
274	МО Краснопахорский, кв-л 188, зу 3/1
1033	МО Краснопахорский, кв-л 220, зу 33
1034	МО Краснопахорский, кв-л 267, зу 1А
1080	МО Краснопахорский, кв-л 267, зу 1А
1043	МО Краснопахорский, кв-л 312, зу 4
361	МО Краснопахорский, кв-л 371, зу 1А
1054	МО Краснопахорский, кв-л 415
366	МО Краснопахорский, кв-л 79
322	МО Краснопахорский, п. Армейский, зу 11
344	МО Краснопахорский, поселок подсобного хозяйства Минзаг, Солнечная ул., зу 20
1078	МО Краснопахорский, поселок подсобного хозяйства Минзаг, Солнечная ул., зу 20
333	МО Краснопахорский, Шаганинские поляны ул., зу 42/2
1083	МО Краснопахорский, Шаганинские поляны ул., зу 42/2
37	МО Солнцево, кв-л 32, зу 17Г
419	МО Солнцево, Татьянин Парк ул., зу 16А
360	МО Филевский парк, Новозаводская ул., зу 18/10
335	МО Филимонковский, г. Московский, зу 1/6, 77:17:0000000:16365
343	МО Филимонковский, д. Марьино, зу 33
357	МО Филимонковский, п. Птичное, ул. Центральная
157	МО Филимонковский, п. Птичное, ул. Центральная, зу 103
144	МО Щербинка, кв-л 105, зу 5
1016	МО Щербинка, кв-л 52, зу 3
800	МО Щербинка, кв-л 91, зу 5
986	МО Щербинка, Остафьевское ш., зу 16
837	МО Щербинка, п. Ерино, мкр-н Санаторий, зу 1
813	МО Щербинка, шоссе Рязановское
1022	Москва, 50:27:0030324:6
337	Некрасовка, рядом с кв-л 14
1074	Некрасовка, рядом с кв-л 14
155	Новобутовская ул., д. 11, д. 13
1079	Новобутовская ул., д. 11, д. 13
347	Новомещерский пр., вл. 9
152	Новосходненское ш., зу 4
941	Окская ул., вл. 13
354	Октябрьская ул., вл 103
923	Октябрьская ул., вл. 103
1063	Оренбургская ул., 77:03:0010005:5328
1064	п. Михайлово-Ярцевское, вблизи д. Терехово
878	п. Первомайское, д. Каменка
802	п. Сосенское, п. Газопровод
832	Парк по Борисовским прудам_Ч. 1
769	Парк по Борисовским прудам_Ч. 2
21	Парк по Борисовским прудам_Ч. 3
920	Парк по Борисовским прудам_Ч. 4
934	Парк по Борисовским прудам_Ч. 5
801	Пехорская ул., вл. 1В/4
599	Плеханова ул., зу 9/1
345	Покровское-Стрешнево_1
147	Покровское-Стрешнево_10
148	Покровское-Стрешнево_11
149	Покровское-Стрешнево_12
150	Покровское-Стрешнево_13
151	Покровское-Стрешнево_2
935	Покровское-Стрешнево_3
1029	Покровское-Стрешнево_4
52	Покровское-Стрешнево_5
61	Покровское-Стрешнево_6
62	Покровское-Стрешнево_7
63	Покровское-Стрешнево_8
64	Покровское-Стрешнево_9
53	Полярная ул., вл. 7, корп. 2
54	пос. Внуковское, д. Пыхтино, зу 25
55	пос. Вороновское, вблизи п. ЛМС
56	пос. Вороновское, д. Львово
57	пос. Вороновское, д. Ясенки
58	пос. Вороновское, п. ЛМС, мкр. Центральный, зу 10Б
59	пос. Вороновское, п. ЛМС, Окружная ул., зу 14
60	пос. Воскресенское, д. Губкино, зу 78
169	пос. Десеновское, в районе д. Яковлево
1044	пос. Десеновское, д. Станиславль, уч. №57Ю
353	пос. Краснопахорское, 0,6 км автодороги д. Раёво, ДНП "Идиллия"_Ч. 1
338	пос. Краснопахорское, 0,6 км автодороги д. Раёво, ДНП "Идиллия"_Ч. 3
352	пос. Краснопахорское, 0,6 км автодороги д. Раёво, ДНП "Идиллия"_Ч. 4
69	пос. Краснопахорское, вблизи п. Минзаг
334	пос. Краснопахорское, д. Красная Пахра, 50:27:0020330:416
1082	пос. Краснопахорское, д. Красная Пахра, 50:27:0020330:416
510	пос. Краснопахорское, д. Красная Пахра, зу 141Б, зу 141 В
994	пос. Краснопахорское, д. Красная Пахра, зу 55Ж
168	Ярославское ш., вл. 36
133	пос. Марушкинское, вблизи дер. Большое Свинорье
134	пос. Марушкинское, ОНО ОПХ "Толстопальцево", зу 19
135	пос. Михайлово-Ярцевское, д. Ярцево
136	пос. Михайлово-Ярцевское, п. Шишкин Лес, д. 45
363	пос. Московский, д. Картмазово
771	пос. Московский, д. Саларьево
336	пос. Московский, д. Саларьево, ул. 2-я Новая
346	пос. Московский, кв-л 34, зу 1
365	пос. Первомайское, д. Жуковка, Осенняя ул., зу 36
143	пос. Первомайское, кв-л 425, зу 1
1053	пос. Рязановское, д. Алхимово, Сосновая ул., д. 5
1055	пос. Рязановское, д. Алхимово, ул. Сосновая, д. 5
350	пос. Рязановское, п. Фабрики им. 1 Мая
774	пос. Сосенское, д. Николо-Хованское
420	пос. Сосенское, д. Сосенки, уч. Владение 114
145	пос. Сосенское, Калужское ш., 21-й км., зу 3А
339	пос. Сосенское, кв-л 129, зу 24
332	пос. Сосенское, кв-л 28
1037	пос. Сосенское, Хованская промзона, вл. 3
348	пос. Филимонковское, кв-л 25, зу 2/2
154	пос. Щаповское, кв-л 216, зу 5/1
1027	пос. Щаповское, кв-л 401, зу 8А
1019	пос. Щаповское, п. Щапово
1052	пос. Щаповское, п. Щапово, зу 21В
1017	пос.Щаповское, вблизи п. Курилово
1028	поселение Вороновское,   вблизи п.ЛМС
1031	поселение Краснопахорское, 0,6 км автодороги д.Раёво, ДНП "Идиллия"
321	поселение Рязановское, шоссе Остафьевское, земельный участок 16 (частично)
1040	Пр. пр. 5217, промзона "Чагино-Капотня"
342	пр-д Черского, вл. 13, к. 4
982	проезд Марьиной Рощи 17-й, вл 13
358	проезд Марьиной Рощи 17-й, вл. 13
364	район Матушкино-Савёлки, парк "Ровестник"
10	Реутовская ул., вл. 7А
13	Российская Федерация, город Москва, внутригородская территория поселение Марушкинское, деревня Крекшино, улица Свободы, вблизи земельного участка 15, с кад. № 77:18:0000000:38840
34	Рязановское поселение, д. Алхимово, ул. Сосновая, дом 5
719	Сельскохозяйственная ул.
327	Сокольнический Вал ул., вл. 2А
323	Сокольнический Вал ул., вл. 37/10
770	Староалексеевская ул., вл. 21, стр. 11
328	Стахановская ул.
933	Тюменская ул., зу 5/10
822	Угрешская, ул., вл 18/1
670	ул. 3-я Радиальная, зу 10Г_Ч. 1
72	ул. 3-я Радиальная, зу 10Г_Ч. 2
839	ул. 3-я Радиальная, зу 10Г_Ч. 3
1020	ул. 3-я Радиальная, зу 10Г_Ч. 4
22	ул. Годовикова, вл. 8а
172	ул. Горбунова, вл. 6
840	ул. Иловайская, д. 10А, напротив
1075	ул. Иловайская, д. 10А, напротив
42	ул. Маршала Ерёменко
988	ул. МЖД Киевское 5-й км
989	ул. Нижние Мнёвники, зу 111
991	улица Маресьева, земельный участок 9\nг. Москва, ул. Пехорская, д. 1В, стр.3
993	участок № 4 Ярославского направления МЖД от ул. Бориса Галушкина до станции Лосиноостровская
927	участок № 5 Савеловской железной дороги
926	Царицыно_1
924	Царицыно_10
1065	Царицыно_11
1066	Царицыно_12
1067	Царицыно_2
1068	Царицыно_3
921	Царицыно_4
1058	Царицыно_5
1059	Царицыно_6
1060	Царицыно_7
843	Царицыно_8
171	Царицыно_9
595	Чермянский пр-д, вл 5
1041	Чермянский пр-д, вл. 5
17	Чермянский пр-д, зу 3
156	Черского пр-д, вл. 13, корп. 4
165	ш. Энтузиастов, рядом с зу 38А
166	Шипиловская ул., вл. 52
167	Широкая ул., зу 2А
48	Шокальского пр-д, д. 52
1086	Шокальского пр-д, д. 52
76	Шоссейная ул., д. 9А, стр. 1
159	Щаповское п., вблизи д. Троицкое_1
160	Щаповское п., вблизи д. Троицкое_2
161	Щаповское п., вблизи д. Троицкое_3
162	Щаповское п., вблизи д. Троицкое_4
163	Щаповское п., вблизи д. Троицкое_5
164	Щаповское п., вблизи д. Троицкое_6
940	Щаповское п., вблизи д. Троицкое_7
798	Щибровская, 37 (г.МОСКВА, ЩИБРОВСКАЯ УЛ., дом 37)
773	Южнопортовая ул., вл. 19А
1	пос. Краснопахорское, 0,6 км автодороги д. Раёво, ДНП "Идиллия"_Ч. 2
\.


--
-- TOC entry 5075 (class 0 OID 16637)
-- Dependencies: 244
-- Data for Name: article; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article (id, article) FROM stdin;
1	1_2_3
2	1_2_4
3	1_2_5
4	1_2_6
5	1_2_7
6	1_2_8
7	1_2_9
8	1_2_10
9	1_2_11
10	1_2_12
11	1_2_13
12	1_2_14
\.


--
-- TOC entry 5051 (class 0 OID 16394)
-- Dependencies: 220
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.districts (id, name) FROM stdin;
8	ВАО
10	ЗАО
11	ЗеЛАО
7	САО
2	СВАО
4	СЗАО
1	ТиНАО
9	ЦАО
6	ЮАО
3	ЮВАО
5	ЮЗАО
12	не указан
\.


--
-- TOC entry 5077 (class 0 OID 16645)
-- Dependencies: 246
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (id, employee) FROM stdin;
1	Горшкова Виктория Арсентьевна
2	Чернышев Артур Игоревич
3	Александрова Маргарита Вадимовна
4	Рыбаков Алексей Артёмович
5	Смирнова Мария Дмитриевна
6	Семенова Дарья Ильинична
7	Скворцов Демид Матвеевич
8	Сахарова Ясмина Романовна
9	Богданова Любовь Ивановна
10	Симонов Марк Александрович
\.


--
-- TOC entry 5067 (class 0 OID 16529)
-- Dependencies: 236
-- Data for Name: objects_for_apartmens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.objects_for_apartmens (id, name) FROM stdin;
1	Нецелевка Домклик (ЗУ)
2	Нецелевка Домклик (Здания)
3	Нецелевка ЦИМПЛ
4	Апартаменты
\.


--
-- TOC entry 5059 (class 0 OID 16428)
-- Dependencies: 228
-- Data for Name: overfly_block1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.overfly_block1 (id, iddistric, idadress, quantitynewviolation, idviolation) FROM stdin;
1	3	42	0	1
2	3	42	0	2
3	3	42	0	2
4	3	1073	0	2
5	3	1073	0	3
6	3	1074	2	3
7	3	1074	2	3
8	3	1075	0	3
9	3	1075	0	3
10	3	1075	0	4
11	3	1075	0	1
12	11	1076	2	3
13	11	1076	2	3
14	11	1076	2	1
15	11	1076	2	3
16	11	1077	5	1
17	11	1077	5	1
18	1	1077	5	1
19	8	1077	5	2
20	11	1077	5	1
21	2	1077	5	1
22	2	1077	5	4
23	2	1077	5	1
24	2	1077	5	1
25	6	1077	5	1
26	6	1077	5	1
27	6	1078	5	2
28	2	1077	5	1
29	2	1077	5	1
30	2	1077	5	3
31	3	1077	5	1
32	6	1077	5	1
33	6	1077	5	1
34	6	1077	5	5
35	7	1077	5	1
36	7	1077	5	1
37	5	1079	0	6
38	1	1078	0	3
39	1	1078	0	2
40	1	1080	2	3
41	1	1080	2	4
42	1	1081	0	2
43	1	1081	0	3
44	1	1081	0	2
45	1	1082	2	2
46	1	1082	2	4
47	1	1082	2	7
48	1	1082	2	3
49	1	1082	2	4
50	1	1082	2	4
51	1	1082	2	4
52	1	1083	0	2
53	11	1084	0	8
54	11	1084	0	1
55	11	1084	0	1
56	11	1084	0	1
57	11	1085	1	6
58	11	1085	1	1
59	11	1085	1	6
60	11	1077	2	3
61	11	1077	2	8
62	11	1077	2	2
63	2	1086	1	1
64	2	1086	1	2
65	2	1086	1	1
66	2	1086	1	2
67	2	1086	1	2
68	10	1087	3	2
69	10	1087	3	7
70	10	1087	3	4
71	10	1087	3	9
72	1	1088	2	3
73	1	1088	2	3
74	1	1088	2	4
75	1	1088	2	4
76	1	1088	2	2
\.


--
-- TOC entry 5061 (class 0 OID 16451)
-- Dependencies: 230
-- Data for Name: overfly_block2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.overfly_block2 (id, num_p_p, id_status, id_adress, id_distric, square) FROM stdin;
134	134	1	1	1	81933
2	2	1	2	2	14662
3	3	1	3	2	15081
4	4	1	4	3	383407
5	5	1	5	1	65632
1035	824	5	6	3	4103265
7	7	2	7	1	\N
8	8	1	8	4	214872
9	9	1	9	3	252062
950	950	1	10	8	5391
12	12	1	12	5	6870
834	834	1	13	1	87711
14	1010	3	14	2	48317
15	15	1	15	1	266194
16	16	2	16	1	\N
783	783	1	17	2	11596
18	18	1	18	1	429578
19	19	1	19	1	204927
20	20	1	20	1	317033
149	149	1	21	6	76985
943	943	1	22	2	17359
23	23	1	23	1	11144
24	24	1	24	1	17595
25	25	1	25	1	332853
1078	1062	3	26	1	131716
27	27	1	27	1	42272
28	28	1	28	1	189737
29	29	1	29	1	245530
30	30	1	30	1	6258
31	31	1	31	1	15360
32	32	1	32	1	5673
33	33	1	33	1	41929
680	680	1	34	1	217564
157	356	3	37	1	28068
850	850	1	38	1	75041
39	39	1	39	1	214164
40	1072	3	40	3	11844
41	41	1	41	1	24633
937	937	1	42	3	984183
43	43	1	43	1	14529
44	44	1	44	1	17453
45	45	1	45	1	2568
46	46	1	46	1	51747
47	47	1	47	6	1312978
860	860	1	48	2	72885
49	49	1	49	6	352683
50	50	1	50	1	45326
51	51	1	51	1	119106
56	56	1	52	4	305957
169	169	1	53	2	7110
1065	76	5	54	1	27402
360	360	1	55	1	31438
1	1	1	56	1	47841
342	372	5	57	1	2153
352	1005	5	57	1	3199
359	359	1	58	1	64702
69	69	1	59	1	6072
361	361	1	59	1	9604
338	370	3	60	1	26868
57	57	1	61	4	368690
58	58	4	62	4	280628
59	59	4	63	4	138814
60	60	4	64	4	169428
138	138	1	65	6	216565
139	139	1	66	6	207023
140	140	1	67	6	180788
141	141	1	68	6	152994
372	1070	3	69	1	28729
70	70	1	70	2	618328
71	71	2	71	2	3230692
1006	144	5	72	6	635512
1071	1054	3	73	8	11739
74	74	1	74	2	103679
853	853	1	75	1	59555
35	1063	3	76	3	1948
77	77	1	77	3	282429
78	78	1	78	2	193097
79	79	1	79	3	523722
80	80	1	80	1	61825
257	257	1	80	1	54931
81	81	1	81	1	2514
82	82	1	82	8	5529
232	232	1	82	8	12896
83	83	1	83	4	20587
197	197	1	83	4	66080
84	84	1	84	4	6225
181	181	1	84	4	35695
85	85	1	85	4	6095
531	531	1	85	4	2325
86	86	5	86	1	9284
87	87	5	87	9	4717
88	88	1	88	9	17421
881	881	1	88	9	115164
89	89	1	89	6	8330
90	90	1	90	10	21317
91	91	1	91	4	21075
92	92	1	92	1	16337
93	93	1	93	9	16566
94	94	1	94	11	58100
95	95	1	95	1	11148
885	885	1	95	1	8863
96	96	5	96	7	315430
97	97	1	97	8	112107
98	98	5	98	3	9046
99	99	1	99	3	23801
100	100	1	100	1	7232
101	101	1	101	11	30794
102	102	5	102	10	24356
103	103	1	103	1	81029
104	104	1	104	8	19594
105	105	1	105	3	17781
106	106	1	106	4	9398
894	894	1	106	4	7659
107	107	1	107	6	16166
108	108	1	108	3	28503
109	109	1	109	4	36850
110	110	5	110	7	34429
111	111	5	111	1	21774
112	112	1	112	6	13068
113	113	5	113	3	3826
114	114	1	114	1	9095
115	115	1	115	3	44121
116	116	1	116	3	63567
117	117	1	117	3	7064
118	118	5	118	3	14194
119	119	1	119	6	19725
120	120	1	120	7	28863
121	121	1	121	2	17101
122	122	1	122	1	30437
123	123	1	123	2	427811
124	124	1	124	2	248693
125	125	1	125	2	219942
126	126	1	126	2	403430
127	127	1	127	2	106650
128	128	1	128	2	427590
129	129	1	129	2	393467
130	130	1	130	2	422397
131	131	1	131	2	414621
132	132	1	132	2	265547
374	374	1	133	1	86690
143	338	3	134	1	791369
1075	1003	3	135	1	12113
1077	1047	3	136	1	2571
953	953	1	137	8	17792
26	1078	3	138	2	4406
1045	1045	1	138	2	4305
945	945	1	139	8	24334
1044	1044	1	139	8	10850
75	75	1	140	2	128208
146	352	3	141	1	145140
1079	325	5	142	1	7726
336	336	1	143	1	356418
1039	1039	1	144	1	49876
1073	1075	5	145	1	549934
679	679	1	146	1	67171
61	61	4	147	4	143649
62	62	1	148	4	258807
63	63	4	149	4	65923
64	64	1	150	4	228704
53	53	4	151	4	374225
844	844	1	152	7	12374
153	153	1	153	11	151602
1061	1061	1	154	1	307855
893	893	1	155	5	27453
168	168	1	156	2	7258
825	825	1	157	1	237343
367	367	1	158	1	8740
279	279	1	159	1	218140
280	280	1	160	1	213545
281	281	1	161	1	185974
282	282	1	162	1	189178
283	283	1	163	1	222074
284	284	1	164	1	88588
946	946	1	165	8	10392
376	376	1	166	6	4112
334	334	1	167	2	120195
170	170	1	168	2	47246
519	519	1	169	1	239886
164	164	1	171	6	1440174
942	942	1	172	10	44949
173	173	1	173	2	9262
174	174	1	174	4	3387
175	175	1	175	11	12600
176	176	1	176	3	24270
177	177	1	177	2	9820
178	178	1	178	8	13110
179	179	1	179	6	45912
180	180	1	180	4	7882
182	182	1	181	4	5699
183	183	1	182	7	7682
184	184	1	183	8	14680
185	185	5	184	1	19778
186	186	1	185	3	27585
187	187	1	186	6	29194
188	188	1	187	4	8117
189	189	5	188	1	5851
190	190	1	189	2	3139
191	191	1	190	5	4632
192	192	1	191	3	24776
193	193	1	192	6	10980
194	194	1	193	2	10529
195	195	1	194	11	13726
196	196	1	195	3	15421
198	198	5	196	4	19045
199	199	1	197	2	6759
200	200	5	198	3	24754
201	201	1	199	2	11171
202	202	1	200	11	18565
203	203	1	201	4	6941
204	204	1	202	11	28663
205	205	1	203	3	11685
206	206	1	204	3	5506
207	207	1	205	11	19313
208	208	1	206	11	11776
209	209	1	207	4	15195
210	210	1	208	3	6342
211	211	1	209	4	8475
212	212	5	210	1	55303
213	213	1	211	5	1436
214	214	5	212	9	18175
215	215	1	213	8	45454
216	216	1	214	4	27350
217	217	1	215	7	72404
218	218	1	216	2	5056
219	219	1	217	8	22747
220	220	1	218	7	17954
221	221	1	219	3	7991
222	222	1	220	1	1920
223	223	5	221	1	28179
224	224	1	222	6	15900
225	225	1	223	6	19491
226	226	1	224	1	8496
227	227	1	225	8	42465
228	228	1	226	2	16444
229	229	1	227	1	8744
230	230	5	228	10	7839
231	231	1	229	1	6957
233	233	1	230	5	27872
234	234	1	231	7	32534
235	235	1	232	2	36673
236	236	5	233	4	14543
237	237	1	234	9	2911
238	238	5	235	9	2170
239	239	1	236	9	2765
240	240	1	237	9	3127
241	241	5	238	9	3320
242	242	5	239	9	1803
243	243	5	240	9	3037
244	244	1	241	5	1390
245	245	1	242	6	5751
246	246	1	243	9	5228
247	247	1	244	7	28252
248	248	1	245	2	21631
249	249	1	246	6	3700
250	250	1	247	9	2304
251	251	1	248	2	7413
252	252	1	249	9	7033
253	253	1	250	6	6132
254	254	1	251	7	8042
255	255	5	252	1	33026
256	256	5	253	3	6565
258	258	1	254	3	21432
259	259	1	255	4	23118
260	260	1	256	3	19515
261	261	1	257	6	21051
262	262	1	258	4	10023
263	263	5	259	8	9426
264	264	1	260	9	24973
265	265	5	261	7	7669
266	266	1	262	4	11167
267	267	5	263	3	5019
268	268	1	264	3	2688
269	269	1	265	1	44473
270	270	5	266	1	9132
271	271	1	267	2	6133
272	272	1	268	2	12437
273	273	1	269	3	55852
274	274	5	270	3	20910
275	275	1	271	2	21977
276	276	1	272	3	14014
277	277	1	273	6	8416
375	375	1	274	1	453589
358	358	1	282	1	14317
287	287	1	283	7	24654
807	807	1	283	7	39222
288	288	1	284	4	13078
289	289	1	285	1	15866
290	290	1	286	6	73938
291	291	1	287	2	71211
292	292	1	288	1	24673
293	293	1	289	8	3696
294	294	1	290	2	10519
295	295	1	291	3	47496
296	296	1	292	7	21378
297	297	5	293	1	8809
298	298	5	294	9	12478
299	299	5	295	1	11502
300	300	1	296	9	70575
301	301	5	297	10	17361
302	302	1	298	8	12139
303	303	5	299	3	14629
304	304	1	300	10	9408
305	305	5	301	9	4959
306	306	1	302	2	3861
308	308	5	304	1	182463
309	309	1	305	2	38983
310	310	1	306	1	11254
311	311	1	307	10	39484
312	312	1	308	4	16466
313	313	1	309	3	10854
314	314	1	310	7	15832
315	315	1	311	3	42003
316	316	1	312	7	42237
317	317	5	313	7	27293
318	318	1	314	1	2566
319	319	1	315	1	2571
320	320	5	316	1	2998
321	321	1	317	8	8335
322	322	1	318	5	8901
323	323	1	319	5	24690
324	324	1	320	10	12787
34	34	1	321	1	33592
339	339	1	322	1	439347
1037	1067	3	323	8	36885
73	73	1	324	2	617744
607	607	1	325	2	168560
579	579	1	326	8	97290
851	851	1	327	8	38451
172	172	1	328	3	1436582
585	585	1	329	2	408567
1002	1002	1	331	6	12687
1047	1033	3	332	1	64879
365	1060	3	333	1	63411
784	784	1	333	1	69217
781	781	1	334	1	10854
812	812	1	335	1	150589
429	429	1	336	1	9943
939	939	1	337	3	23309
135	135	1	338	1	116771
1034	1034	1	339	1	2637
370	1066	3	340	1	16063
344	344	1	341	1	13248
331	331	1	342	2	9991
1003	335	3	343	1	7307
347	347	1	344	1	17201
52	52	4	345	4	181992
145	343	3	346	1	128487
814	814	1	347	10	138479
325	365	3	348	1	6147
335	366	3	349	1	8622
154	154	1	350	1	58930
328	328	1	351	1	3681
136	136	1	352	1	80384
133	133	1	353	1	109552
21	1038	3	354	2	52721
38	38	1	355	1	48354
842	842	1	356	1	16215
849	849	1	357	1	25061
780	780	1	358	2	31223
782	782	1	359	1	14139
1033	811	3	360	10	1734806
37	37	1	361	1	83130
353	353	1	361	1	155121
1051	1051	1	361	1	147287
355	355	1	362	1	12161
356	1032	3	363	1	7090
332	332	1	364	11	151504
343	1004	3	365	1	14171
369	369	1	366	1	398529
377	377	5	368	1	3134
378	378	1	369	7	11146
379	379	1	370	7	19360
380	380	1	371	1	521734
381	381	1	372	7	4740
382	382	1	373	2	11638
383	383	1	374	10	5859
384	384	1	375	10	7586
385	385	1	376	2	7189
386	386	1	377	8	4484
387	387	1	378	8	3007
388	388	1	379	3	38310
389	389	1	380	4	4579
390	390	1	381	4	6472
391	391	5	382	1	4779
392	392	1	383	6	21096
393	393	1	384	3	21955
394	394	1	385	6	14279
395	395	1	386	6	13417
396	396	1	387	10	7869
397	397	1	388	1	3510
398	398	1	389	10	28755
399	399	1	390	10	20089
400	400	5	391	1	20230
401	401	1	392	6	10279
402	402	1	393	3	15273
403	403	1	394	1	6172
404	404	5	395	10	7637
405	405	1	396	11	95085
406	406	5	397	10	7023
407	407	5	398	10	8253
408	408	1	399	2	4580
409	409	1	400	1	2787
410	410	5	401	1	21893
411	411	1	402	4	28136
412	412	1	403	1	18976
413	413	1	404	3	29241
414	414	1	405	8	5309
415	415	1	406	8	31700
416	416	1	407	11	124318
417	417	1	408	2	14797
418	418	1	409	8	34415
419	419	1	410	8	14801
420	420	1	411	1	52189
421	421	1	412	9	25065
422	422	1	413	3	15912
423	423	5	414	9	3070
424	424	5	415	9	8933
425	425	1	416	6	7273
426	426	1	417	3	19983
427	427	1	418	5	15152
144	342	3	419	1	9413
1036	1036	1	420	1	2191
430	430	1	421	3	16782
431	431	1	422	3	47393
432	432	1	423	2	8205
433	433	1	424	10	41837
434	434	1	425	3	38208
435	435	5	426	9	7074
436	436	1	427	2	34842
437	437	1	428	8	4559
438	438	1	429	1	8749
439	439	1	430	8	25765
440	440	1	431	9	8307
441	441	5	432	1	17684
442	442	1	433	4	31156
443	443	1	434	3	97619
444	444	1	435	8	7640
445	445	1	436	8	5671
446	446	1	437	5	16698
447	447	1	438	6	8457
448	448	5	439	7	28981
449	449	1	440	6	6297
450	450	5	441	7	8298
451	451	1	442	3	12669
452	452	1	443	1	3358
453	453	1	444	8	10870
454	454	1	445	4	1634
455	455	1	446	5	18081
456	456	1	447	7	18052
457	457	1	448	11	10662
458	458	1	449	2	18497
459	459	1	450	3	16159
460	460	1	451	3	32943
461	461	1	452	11	8880
462	462	1	453	6	23372
463	463	1	454	2	22735
465	465	1	456	6	88600
466	466	5	457	7	21685
467	467	1	458	4	19156
468	468	1	459	4	764829
469	469	1	460	3	7866
470	470	5	461	3	38083
471	471	1	462	7	18029
472	472	1	463	4	152767
473	473	1	464	1	37362
474	474	1	465	7	18665
475	475	1	466	8	207616
476	476	1	467	3	10071
477	477	5	468	9	2735
478	478	1	469	3	10839
479	479	1	470	2	11677
480	480	1	471	8	26636
481	481	1	472	8	39440
482	482	1	473	8	15959
483	483	5	474	9	21610
484	484	1	475	1	3461
485	485	1	476	7	2415
486	486	1	477	6	15470
487	487	1	478	8	222001
488	488	1	479	3	44185
489	489	1	480	1	19228
490	490	1	481	10	11650
491	491	1	482	1	23493
492	492	1	483	4	29390
494	494	1	485	8	8481
495	495	5	486	8	16390
496	496	1	487	1	7993
497	497	1	488	6	17489
498	498	1	489	6	17196
499	499	5	490	8	79905
500	500	1	491	4	44823
501	501	5	492	3	17592
502	502	1	493	1	9669
503	503	1	494	7	6200
504	504	1	495	8	15062
505	505	1	496	5	21249
506	506	5	497	1	3048
507	507	5	498	3	148084
508	508	1	499	1	35217
509	509	1	500	2	41114
510	510	1	501	7	24952
511	511	1	502	6	15169
512	512	1	503	1	26637
513	513	1	504	6	19466
514	514	1	505	6	13880
515	515	1	506	3	43406
516	516	5	507	3	2749
517	517	4	508	3	22117
518	518	1	509	4	18999
340	340	1	510	1	539128
520	520	1	511	1	23903
521	521	1	512	6	34480
522	522	1	513	4	21463
523	523	1	514	3	22007
524	524	1	515	7	10111
525	525	5	516	3	711313
526	526	1	517	10	15880
527	527	1	518	7	30520
528	528	1	519	3	31865
529	529	1	520	1	15896
530	530	1	521	8	3109
532	532	1	522	4	31987
533	533	5	523	2	22102
534	534	1	524	9	3668
535	535	1	525	4	7794
536	536	5	526	10	8110
537	537	1	527	1	7222
538	538	1	528	8	16269
539	539	5	529	10	7710
540	540	1	530	6	7927
541	541	1	531	10	80347
542	542	1	532	2	16128
543	543	5	533	4	11635
544	544	1	534	5	12221
545	545	1	535	10	11082
546	546	1	536	7	5215
547	547	5	537	1	4621
548	548	1	538	2	5514
549	549	1	539	10	32039
550	550	1	540	7	49565
551	551	1	541	2	22021
552	552	1	542	5	45955
553	553	1	543	8	36884
554	554	1	544	2	4661
555	555	1	545	6	32563
556	556	1	546	1	12252
557	557	1	547	6	14681
558	558	5	548	4	22533
559	559	1	549	1	5596
560	560	1	550	1	3379
561	561	1	551	1	13481
562	562	1	552	2	25004
563	563	1	553	3	21231
564	564	1	554	3	12601
565	565	1	555	4	13071
566	566	5	556	1	56291
567	567	1	557	1	1961
568	568	5	558	1	7841
569	569	1	559	6	3078
570	570	1	560	6	25674
571	571	1	561	11	9828
572	572	1	562	4	18043
573	573	1	563	5	182896
574	574	1	564	10	75612
575	575	5	565	1	24897
576	576	1	566	7	16421
577	577	1	567	1	6504
578	578	1	568	3	155841
612	612	1	569	3	498091
68	68	1	570	7	1532424
329	329	1	571	1	623441
1059	611	5	572	1	363557
583	583	1	573	10	105489
584	584	1	574	6	301908
588	588	1	575	3	139006
589	589	1	576	2	117015
590	590	1	577	2	128546
811	22	3	578	1	134913
592	592	1	579	11	131359
606	606	1	580	1	226559
587	587	1	581	3	275453
330	330	1	582	6	119803
595	595	1	583	7	369849
597	597	1	584	1	274500
599	599	1	585	8	295303
600	600	1	586	6	624106
613	613	1	587	4	436528
601	601	1	588	10	1042890
614	614	1	589	10	159743
615	615	1	590	6	1076926
617	617	1	591	6	155761
371	371	1	592	1	5510
158	357	5	593	1	17072
363	1059	3	594	1	58624
368	368	1	594	1	72673
957	957	1	595	2	65114
1057	609	5	596	3	294001
582	582	1	597	3	205662
610	610	1	598	8	158809
1048	1048	1	599	8	18152
594	594	1	600	1	469274
611	17	3	601	1	77675
598	598	1	602	3	1367774
616	616	1	603	7	230332
618	618	1	604	7	215912
619	619	1	605	2	184864
620	620	1	606	6	194796
621	621	1	607	7	252282
622	622	1	608	3	433510
623	623	1	609	3	509122
624	624	1	610	10	406451
1060	625	5	611	8	37587
626	626	1	612	10	142345
627	627	1	613	10	47085
628	628	1	614	3	677216
625	21	3	615	1	9565
603	603	1	616	6	256465
604	604	1	617	2	2298783
286	363	5	618	1	15048
629	629	1	619	11	21430
630	630	1	620	11	56427
631	631	1	621	5	44268
632	632	1	622	8	12562
633	633	1	623	1	20957
634	634	5	624	1	23786
635	635	5	625	1	5351
636	636	1	626	1	12933
637	637	1	627	1	15078
638	638	5	628	10	269353
639	639	1	629	7	17279
640	640	1	630	1	276741
641	641	5	631	10	36915
642	642	1	632	4	1637
643	643	5	633	3	13448
644	644	5	634	1	10972
645	645	1	635	11	20945
646	646	2	636	6	13074
647	647	1	637	2	4738
648	648	5	638	3	81198
649	649	1	639	2	32931
650	650	1	640	9	331135
651	651	5	641	2	36732
652	652	1	642	6	5579
653	653	1	643	7	17681
654	654	1	644	2	9525
655	655	1	645	5	22963
656	656	1	646	2	4427
657	657	5	647	3	33424
658	658	1	648	10	21628
659	659	1	649	5	8088
660	660	1	650	3	103690
661	661	1	651	6	86404
662	662	1	652	10	35559
663	663	5	653	1	14048
664	664	1	654	3	13709
665	665	1	655	1	16301
666	666	1	656	8	43376
667	667	1	657	10	22476
668	668	1	658	1	12066
669	669	5	659	3	22152
670	670	5	660	3	18570
671	671	1	661	1	17827
672	672	1	662	3	17812
673	673	1	663	7	7482
674	674	1	664	2	4550
675	675	1	665	1	27936
676	676	5	666	10	20671
677	677	1	667	7	26508
678	678	5	668	7	22574
278	278	1	669	1	19802
1005	143	5	670	6	211295
681	681	1	671	7	42466
682	682	1	672	5	8441
683	683	1	673	2	8215
684	684	1	674	4	46476
685	685	1	675	7	168120
686	686	1	676	1	7618
687	687	1	677	8	3434
688	688	5	678	8	23574
689	689	1	679	8	14069
690	690	1	680	11	53646
691	691	1	681	10	9765
693	693	1	683	3	12703
694	694	1	684	3	35067
695	695	1	685	10	16395
696	696	1	686	2	9210
697	697	1	687	1	11228
698	698	1	688	7	9421
699	699	1	689	8	9425
700	700	5	690	11	38188
701	701	1	691	1	168765
702	702	1	692	3	22840
703	703	1	693	3	27635
704	704	1	694	4	23973
705	705	1	695	10	9306
706	706	1	696	10	113093
707	707	5	697	1	8758
708	708	1	698	2	6312
709	709	1	699	1	6870
710	710	1	700	8	30994
711	711	1	701	8	137525
712	712	1	702	3	27768
713	713	1	703	6	154859
714	714	1	704	7	36794
715	715	1	705	10	210229
716	716	1	706	4	10452
717	717	1	707	2	11412
718	718	1	708	10	29933
719	719	1	709	2	31278
720	720	1	710	7	15188
721	721	1	711	2	11298
722	722	1	712	3	7536
723	723	1	713	10	12170
725	725	5	715	2	30093
726	726	1	716	10	17536
727	727	1	717	7	15129
728	728	1	718	10	26399
72	72	1	719	2	392553
730	730	1	720	2	19780
731	731	1	721	6	34645
732	732	5	722	9	4816
733	733	1	723	5	9020
734	734	1	724	2	18517
735	735	5	725	9	23486
736	736	1	726	3	34903
737	737	1	727	3	19647
738	738	1	728	1	8461
739	739	5	729	1	13270
740	740	1	730	1	9225
741	741	1	731	6	20837
742	742	5	732	3	77692
743	743	1	733	2	19586
744	744	1	734	1	17247
745	745	5	735	1	10378
746	746	5	736	9	13938
748	748	1	738	2	11712
749	749	1	739	8	8498
750	750	5	740	1	37447
751	751	5	741	10	22888
752	752	5	742	1	9792
753	753	1	743	9	29706
754	754	1	744	4	8743
755	755	1	745	3	188559
756	756	1	746	6	94719
757	757	1	747	1	23702
758	758	1	748	1	20452
759	759	1	749	1	5002
760	760	1	750	1	23066
761	761	1	751	3	765829
762	762	1	752	9	43559
763	763	1	753	3	46490
764	764	1	754	6	12548
765	765	1	755	9	14193
766	766	1	756	5	18477
767	767	5	757	1	8465
768	768	1	758	7	15400
769	769	1	759	7	27651
770	770	1	760	8	16520
771	771	1	761	3	26572
772	772	1	762	2	9746
773	773	1	763	1	5116
774	774	1	764	4	19036
775	775	1	765	3	21925
776	776	1	766	1	51485
777	777	1	767	11	34994
778	778	1	768	4	81184
148	148	1	769	6	73695
22	1076	3	770	2	5128
785	785	1	771	1	17145
1050	1035	3	771	1	10759
1068	1052	3	772	8	781528
36	1064	3	773	3	13980
1046	1006	3	774	1	18170
786	786	4	775	3	27992
787	787	1	776	2	6178
788	788	5	777	9	13394
789	789	1	778	10	28153
790	790	5	779	1	35778
791	791	1	780	1	8032
792	792	4	781	3	45489
793	793	1	782	2	10164
794	794	5	783	3	30126
795	795	1	784	11	24088
796	796	1	785	11	286155
797	797	1	786	4	33556
798	798	1	787	11	6833
799	799	5	788	10	15664
800	800	1	789	5	46713
801	801	1	790	1	33412
802	802	5	791	1	12751
803	803	1	792	3	63410
804	804	1	793	1	6975
805	805	1	794	2	47295
806	806	5	795	7	23523
808	808	1	796	8	6453
941	941	1	797	11	193414
11	11	1	798	5	506
608	608	1	799	6	498220
155	155	1	800	1	40821
952	952	1	801	8	5915
349	349	1	802	1	10257
815	815	1	803	7	16270
816	816	1	804	8	19191
817	817	5	805	10	69426
818	818	1	806	10	57071
819	819	1	807	1	34118
820	820	1	808	1	10647
821	821	1	809	3	20322
822	822	1	810	6	15273
823	823	1	811	10	7227
824	26	3	812	1	3488
958	958	1	813	1	12419
826	826	1	814	4	106744
827	827	1	815	9	85416
828	828	1	816	6	10694
829	829	5	817	10	28574
830	830	1	818	2	544240
831	831	1	819	1	98874
832	832	1	820	3	12321
833	833	1	821	8	53997
42	1073	3	822	3	15713
835	835	1	823	1	6766
836	836	1	824	10	4347
837	837	5	825	1	12431
838	838	5	826	1	7916
839	839	1	827	1	6521
840	840	1	828	3	27696
841	841	1	829	5	22935
1055	1056	3	830	1	31828
848	848	1	831	8	601402
147	147	1	832	6	106194
847	847	1	833	8	1567872
6	6	1	834	3	318764
858	858	1	835	6	115972
944	944	1	835	6	132388
997	997	1	836	2	9287
152	152	1	837	1	177032
1070	1053	3	838	8	261365
1008	145	5	839	6	592591
940	940	1	840	3	13671
1056	1057	3	841	1	31849
854	854	1	842	2	179908
1074	1074	1	842	2	164087
163	163	1	843	6	980215
856	856	1	844	3	111433
586	586	1	845	8	109694
65	65	1	846	7	1263171
137	137	1	847	6	306895
862	862	1	849	5	15060
863	863	1	850	4	51345
864	864	1	851	1	21328
865	865	1	852	7	53620
866	866	1	853	6	82287
867	867	1	854	10	99561
868	868	1	855	2	81599
869	869	1	856	4	331373
870	870	1	857	3	28078
871	871	1	858	5	133695
872	872	1	859	1	6918
873	873	1	860	2	11521
874	874	1	861	1	6792
875	875	5	862	1	98832
876	876	1	863	1	19147
877	877	1	864	1	97227
878	878	1	865	5	6393
879	879	1	866	2	15193
880	880	1	867	3	11405
882	882	5	868	1	25387
883	883	1	869	10	10151
884	884	1	870	6	13829
886	886	1	871	4	53428
887	887	1	872	8	10281
888	888	5	873	1	80108
889	889	1	874	6	15953
890	890	1	875	6	35886
891	891	1	876	11	12024
892	892	1	877	8	15158
609	14	3	878	1	9594
895	895	1	879	6	23602
896	896	1	880	2	17633
897	897	1	881	3	6771
898	898	5	882	1	65454
899	899	1	883	8	31026
900	900	1	884	3	23478
901	901	1	885	6	34198
902	902	1	886	3	66085
903	903	1	887	4	6289
904	904	1	888	3	16396
905	905	1	889	2	25599
906	906	1	890	11	182181
907	907	1	891	6	18746
908	908	1	892	7	32115
909	909	1	893	7	9138
910	910	5	894	7	11002
911	911	1	895	5	69545
912	912	1	896	7	21218
913	913	1	897	7	22508
914	914	1	898	6	54707
915	915	1	899	11	12924
916	916	1	900	1	49367
917	917	1	901	2	22968
918	918	1	902	7	9630
919	919	1	903	3	7138
920	920	1	904	6	9758
921	921	5	905	9	14186
922	922	1	906	3	48207
923	923	1	907	6	3047
924	924	1	908	10	20675
925	925	1	909	7	12896
926	926	1	910	3	29574
927	927	1	911	4	35345
928	928	1	912	11	31615
929	929	1	913	1	35469
930	930	1	914	4	18017
931	931	1	915	3	124408
932	932	5	916	9	19909
933	933	1	917	11	33604
934	934	1	918	9	29015
935	935	1	919	11	41851
150	150	1	920	6	104730
159	159	1	921	6	763478
1067	1000	3	922	8	25027
936	936	1	923	2	53811
165	165	1	924	6	1064640
581	581	1	925	3	201435
156	156	1	926	6	1355842
17	1011	3	927	2	226818
345	345	2	928	1	\N
947	947	1	930	10	16676
948	948	1	931	5	132825
949	949	1	932	7	43022
852	852	1	933	8	33300
151	151	1	934	6	93805
54	54	4	935	4	482212
364	364	1	936	1	67071
954	35	3	937	1	118079
955	36	3	938	1	34952
956	40	3	939	1	17605
285	285	1	940	1	285272
779	779	1	941	3	46488
959	959	1	942	2	9064
960	960	1	943	1	29785
961	961	5	944	1	7868
962	962	5	945	10	38058
963	963	1	946	1	21409
964	964	1	947	1	12662
965	965	1	948	1	46895
966	966	5	949	2	15777
967	967	1	950	1	3650
968	968	1	951	3	34872
969	969	1	952	3	11556
970	970	5	953	1	43815
971	971	1	954	3	70741
972	972	1	955	8	9790
973	973	1	956	3	9394
974	974	1	957	2	37974
975	975	1	958	1	5996
976	976	1	959	3	12559
977	977	1	960	6	28906
978	978	1	961	7	196540
979	979	1	962	4	4316
980	980	1	963	3	51202
981	981	1	964	7	17455
982	982	5	965	9	5286
983	983	5	966	7	12793
984	984	1	967	3	34405
985	985	1	968	3	32996
986	986	5	969	4	17294
987	987	5	970	10	42723
988	988	1	971	6	7484
989	989	1	972	2	7353
990	990	5	973	7	16413
991	991	1	974	2	23090
992	992	5	975	1	4291
993	993	5	976	4	30326
994	994	5	977	4	19750
995	995	1	978	2	19889
996	996	1	979	3	23036
859	859	1	980	10	2223913
998	998	1	981	6	6793
327	327	1	982	2	26837
1000	42	3	983	1	22100
1001	1001	1	984	2	12418
843	843	1	985	3	200764
351	351	1	986	1	87028
1004	48	5	987	6	1720265
855	855	1	988	10	124461
171	171	1	989	4	317484
1007	1007	1	990	5	13899
605	605	1	991	3	3502790
1009	1009	1	992	6	17494
1062	1037	3	993	2	1807775
350	350	1	994	1	59056
357	1050	3	994	1	60422
1012	1012	1	995	7	34306
1013	1013	5	996	1	60618
1014	1014	5	997	4	321052
1015	1015	5	998	1	5766
1016	1016	5	999	10	9274
1017	1017	5	1000	1	1780
1018	1018	1	1001	1	3402
1019	1019	5	1002	4	25809
1020	1020	1	1003	3	144511
1021	1021	1	1004	3	11296
1022	1022	5	1005	3	37317
1023	1023	1	1006	1	4519
1024	1024	5	1007	8	3401267
1025	1025	5	1008	3	127729
1026	1026	5	1009	8	1031
1027	1027	1	1010	6	69921
1028	1028	1	1011	2	57453
1029	1029	1	1012	4	5164
1030	1030	1	1013	3	28909
1031	1031	1	1014	1	17475
1032	1068	3	1015	8	865
341	341	1	1016	1	386880
373	373	1	1017	1	2654
66	66	1	1018	7	1011814
999	999	1	1019	1	75188
1010	146	5	1020	6	655795
1064	1008	3	1021	1	50681
362	362	1	1022	1	454364
1040	954	3	1023	1	21591
1069	1069	1	1024	5	5374
1042	955	3	1025	1	293222
67	67	1	1026	7	1176427
346	346	1	1027	1	536230
10	10	1	1028	1	28180
55	55	4	1029	4	402176
1041	1041	1	1030	8	1697507
13	13	1	1031	1	521844
1054	1055	3	1032	1	34784
326	326	1	1033	1	195344
348	348	1	1034	1	195385
1076	1046	3	1035	1	92712
593	593	1	1036	1	229168
1052	1040	3	1037	1	54655
596	596	1	1038	5	268990
602	602	1	1039	3	499722
729	729	1	1040	3	259498
810	810	4	1041	2	98997
580	580	1	1042	10	44880
337	337	1	1043	1	410978
1011	1077	3	1044	1	84201
1066	956	3	1045	8	23939
1043	1043	1	1046	6	9671
845	845	1	1047	8	157565
142	142	1	1048	6	366878
846	846	1	1049	8	651167
938	938	1	1050	3	342353
1072	1071	3	1051	8	3310
366	1065	3	1052	1	43016
1058	1058	1	1053	1	130158
428	428	1	1054	1	522429
354	354	4	1055	1	\N
1038	286	3	1056	1	367752
1053	1042	3	1057	1	15923
160	160	1	1058	6	1240475
161	161	1	1059	6	1386956
162	162	1	1060	6	1173219
1063	1079	3	1061	2	19117
1049	1049	1	1062	2	15186
951	951	1	1063	8	9420
813	813	1	1064	1	1017444
166	166	1	1065	6	734058
167	167	1	1066	6	262270
48	157	5	1067	6	1906051
76	158	5	1068	6	1125155
809	809	1	1069	11	42028
861	861	2	1069	11	\N
333	333	1	1070	11	170147
857	857	1	1071	11	104217
591	591	1	1072	11	184967
307	307	1	303	7	16597
464	464	1	455	7	28353
493	493	1	484	8	53343
692	692	1	682	8	152646
724	724	1	690	4	87779
747	747	1	716	1	34468
\.


--
-- TOC entry 5071 (class 0 OID 16588)
-- Dependencies: 240
-- Data for Name: photos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.photos (id, date_discharge, confirmed_signs_of_violations, other_violations, new_violations, id_type) FROM stdin;
1	2025-04-02	0	0	51	1
2	2025-08-30	0	4	6	1
3	2025-12-02	9	17	1	1
4	2025-12-02	24	0	21	1
5	2026-01-28	1	0	0	1
6	2026-01-28	574	0	582	1
7	2026-03-16	13	0	0	1
8	2026-03-16	1	0	0	1
9	2026-01-26	0	0	0	2
10	2026-02-10	0	0	0	2
11	2026-02-10	1	0	0	2
12	2026-03-06	1	0	1	2
13	2026-01-26	18	2	5	2
22	2025-10-27	295	101	127	3
23	2026-01-21	190	41	80	3
32	2026-01-27	16	0	1	4
\.


--
-- TOC entry 5063 (class 0 OID 16494)
-- Dependencies: 232
-- Data for Name: robots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.robots (id, name, short_name) FROM stdin;
1	Контроль деятельности инспекторов	014U
2	Контроль мероприятий 	001Р
3	Загрузка обращений из ЭДО и формирование задач в АИС ГИН 	010U
4	Формирование отчетов по контролям в ЭДО 	011Р
5	Регистрация исходящих документов в ЭДО 	004U
6	Отправка исходящих писем с реестром УОРД в ЭДО 	 003U
7	Создание поручений по протоколам ЭДО 	012U
8	Чат-бот "Мосапарт" 	023Ру
9	Чат-бот "Виртуальный помощник" 	018Ру
10	Чат-бот "Самострой" 	009Ру
11	Чат-бот по торговому сбору 	008Ру
12	Чат-бот "Свободный доступ" 	 006Ру
\.


--
-- TOC entry 5065 (class 0 OID 16512)
-- Dependencies: 234
-- Data for Name: robots_analitic; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.robots_analitic (id, idrobots, datestatistic, count_application, isactive, data_analize) FROM stdin;
1	1	2025-10-01	433	t	{"результаты_проверок": {"type": "Pie", "сумма": 433, "детали": {"Не определено": 70, "Не допуск на объект": 4, "Демонтаж подтвержден": 20, "Не выявлено нарушений": 218, "Демонтаж не подтвержден": 8, "Выявлены признаки правонарушения": 19, "Выявленные ранее нарушения устранены": 1, "Выявлено одно или несколько нарушений": 68, "Выявленные ранее нарушения не устранены": 22, "Определение площади самовольного строительства": 3}}, "количество_проведенных_проверок": {"type": "Bar", "сумма": 433, "детали": {"УРК": 68, "УРД и МВ": 3, "УКОН на ПТ": 37, "УКОН по ВАО": 28, "УКОН по ЗАО": 39, "УКОН по САО": 23, "УКОН по ЦАО": 44, "УКОН по ЮАО": 76, "УКОН по СВАО": 19, "УКОН по СЗАО": 29, "УКОН по ЮВАО": 36, "УКОН по ЮЗАО": 23, "ОКОН по ЗелАО": 8}}, "количество_сформированных_отчетов": {"type": "Pie", "сумма": 52, "детали": {"УКОН на ПТ": 5, "УКОН по ВАО": 5, "УКОН по ЗАО": 5, "УКОН по САО": 5, "УКОН по ЦАО": 5, "УКОН по ЮАО": 5, "УКОН по СВАО": 5, "УКОН по СЗАО": 4, "УКОН по ЮВАО": 5, "УКОН по ЮЗАО": 5, "УКОН по ЗелАО": 3}}}
2	1	2025-11-01	927	t	{"результаты_проверок": {"type": "Pie", "сумма": 927, "детали": {"Не определено": 259, "Не допуск на объект": 3, "Демонтаж подтвержден": 34, "Не выявлено нарушений": 364, "Демонтаж не подтвержден": 15, "Выявлены признаки правонарушения": 61, "Выявленные ранее нарушения устранены": 3, "Выявлено одно или несколько нарушений": 126, "Выявленные ранее нарушения не устранены": 59, "Выявлены признаки готовящегося правонарушения": 2, "Определение площади самовольного строительства": 1}}, "количество_проведенных_проверок": {"type": "Bar", "сумма": 927, "детали": {"УРК": 77, "УК на ПТ": 200, "УРД и МВ": 1, "УКОН по ВАО": 43, "УКОН по ЗАО": 147, "УКОН по САО": 73, "УКОН по ЦАО": 66, "УКОН по ЮАО": 73, "УКОН по СВАО": 64, "УКОН по СЗАО": 56, "УКОН по ЮВАО": 63, "УКОН по ЮЗАО": 35, "ОКОН по ЗелАО": 29}}, "количество_сформированных_отчетов": {"type": "Pie", "сумма": 44, "детали": {"УКОН на ПТ": 4, "УКОН по ВАО": 4, "УКОН по ЗАО": 4, "УКОН по САО": 4, "УКОН по ЦАО": 4, "УКОН по ЮАО": 4, "УКОН по СВАО": 4, "УКОН по СЗАО": 4, "УКОН по ЮВАО": 4, "УКОН по ЮЗАО": 4, "УКОН по ЗелАО": 4}}}
3	1	2025-12-01	1054	t	{"результаты_проверок": {"type": "Pie", "сумма": 1054, "детали": {"Не определено": 113, "Верифицировано": 815, "Отправлено на верификацию": 126}}, "количество_проведенных_проверок": {"type": "Bar", "сумма": 1054, "детали": {"УРК": 109, "УК на ПТ": 185, "УРД и МВ": 4, "УКОН по ВАО": 67, "УКОН по ЗАО": 74, "УКОН по САО": 122, "УКОН по ЦАО": 93, "УКОН по ЮАО": 109, "УКОН по СВАО": 53, "УКОН по СЗАО": 71, "УКОН по ЮВАО": 90, "УКОН по ЮЗАО": 53, "ОКОН по ЗелАО": 24}}, "количество_сформированных_отчетов": {"type": "Pie", "сумма": 108, "детали": {"УКОН на ПТ": 10, "УКОН по ВАО": 10, "УКОН по ЗАО": 10, "УКОН по САО": 10, "УКОН по ЦАО": 8, "УКОН по ЮАО": 10, "УКОН по СВАО": 10, "УКОН по СЗАО": 10, "УКОН по ЮВАО": 10, "УКОН по ЮЗАО": 10, "УКОН по ЗелАО": 10}}}
7	3	2025-10-01	8685	t	{"причина_не_передачи": {"type": "Pie", "сумма": 855, "детали": {"Ответ/ОФИ": 88, "Не подходит": 64, "Адрес не найден": 229, "Снят с контроля": 51, "Неверный формат КН": 2, "Округ или район не найден": 4, "Найдено несколько адресов": 4, "Нет резолюции на ответственное лицо": 407, "Не удалось отправить запрос в АИС ГИН": 1, "Размер файлов превышает допустимый размер": 4, "Несоответствие параметров типу запрашиваемого объекта": 1}}, "суммарное_количество_документов": {"type": "Pie", "сумма": 8685, "детали": {}}, "количество_успешно_сформированных_пакетов_документов_для_передачи_в_аис_гин": {"type": "Pie", "сумма": 95, "детали": {}}}
8	3	2025-11-01	17953	t	{"причина_не_передачи": {"type": "Pie", "сумма": 2286, "детали": {"Ответ/ОФИ": 98, "Не подходит": 91, "Адрес не найден": 472, "Снят с контроля": 127, "Округ или район не найден": 16, "Найдено несколько адресов": 17, "Нет резолюции на ответственное лицо": 1437, "Неверный формат кадастрового номера": 1, "Не удалось отправить запрос в АИС ГИН": 16, "Размер файлов превышает допустимый размер": 8, "Введённые параметры не соответствуют типу запрашиваемого объекта": 3}}, "суммарное_количество_документов": {"type": "Pie", "сумма": 17953, "детали": {}}, "количество_успешно_сформированных_пакетов_документов_для_передачи_в_аис_гин": {"type": "Pie", "сумма": 335, "детали": {}}}
9	3	2025-12-01	12689	t	{"причина_не_передачи": {"type": "Pie", "сумма": 2857, "детали": {"Ответ/ОФИ": 110, "Не подходит": 75, "Адрес не найден": 437, "Снят с контроля": 109, "Система РЕОН недоступна": 1, "Округ или район не найден": 9, "Найдено несколько адресов": 19, "Нет резолюции на ответственное лицо": 2067, "Не удалось отправить запрос в АИС ГИН": 18, "Размер файлов превышает допустимый размер": 7, "Введенные параметры не соответствуют типу запрашиваемого объекта": 5}}, "суммарное_количество_документов": {"type": "Pie", "сумма": 12689, "детали": {}}, "количество_успешно_формированных_пакетов_документов_для_передачи_в_аис_гин": {"type": "Pie", "сумма": 269, "детали": {}}}
10	4	2025-10-01	142	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 68, "детали": {"Нет документов с контрольной датой": 53, "Исполнитель не найден в файле \\"По контролям направлять.xlsx\\"": 15}}, "количество_обработанных_исполнителей": {"type": "Pie", "сумма": 142, "детали": {}}}
16	6	2025-10-01	1162	t	{"количество_обработанных_документов": {"type": "Pie", "сумма": 296, "детали": {"ЭЦП": 229, "Почта простое": 0, "Почта заказное": 23, "Почта бандероль": 30, "Почта заказное с уведомлением": 14}}, "количество_необработанных_документов": {"type": "Pie", "сумма": 866, "детали": {"ЭЦП": 637, "Почта простое": 0, "Почта заказное": 204, "Почта бандероль": 0, "Почта заказное с уведомлением": 25}}, "количество_проверенных_документов_по_типам": {"type": "Bar", "сумма": 1162, "детали": {"ЭЦП": 866, "Почта простое": 0, "Почта заказное": 227, "Почта бандероль": 30, "Почта заказное с уведомлением": 39}}}
17	6	2025-11-01	3819	t	{"количество_обработанных_документов": {"type": "Pie", "сумма": 841, "детали": {"ЭЦП": 457, "Почта простое": 8, "Почта заказное": 98, "Почта бандероль": 163, "Почта заказное с уведомлением": 115}}, "количество_необработанных_документов": {"type": "Pie", "сумма": 2978, "детали": {"ЭЦП": 2487, "Почта простое": 1, "Почта заказное": 436, "Почта бандероль": 3, "Почта заказное с уведомлением": 51}}, "количество_проверенных_документов_по_типам": {"type": "Bar", "сумма": 3819, "детали": {"ЭЦП": 2944, "Почта простое": 9, "Почта заказное": 534, "Почта бандероль": 166, "Почта заказное с уведомлением": 166}}}
18	6	2025-12-01	4671	t	{"количество_обработанных_документов": {"type": "Pie", "сумма": 779, "детали": {"ЭЦП": 315, "Почта простое": 9, "Почта заказное": 158, "Почта бандероль": 233, "Почта заказное с уведомлением": 64}}, "количество_необработанных_документов": {"type": "Pie", "сумма": 3892, "детали": {"ЭЦП": 3577, "Почта простое": 1, "Почта заказное": 253, "Почта бандероль": 8, "Почта заказное с уведомлением": 53}}, "количество_проверенных_документов_по_типам": {"type": "Bar", "сумма": 4671, "детали": {"ЭЦП": 3892, "Почта простое": 10, "Почта заказное": 411, "Почта бандероль": 241, "Почта заказное с уведомлением": 117}}}
19	7	2025-10-01	116	t	{"география_запросов": {"type": "Bar", "сумма": 116, "детали": {"ВАО": 15, "ЗАО": 14, "САО": 11, "ЦАО": 9, "ЮАО": 1, "СВАО": 12, "СЗАО": 12, "ЮВАО": 13, "ЮЗАО": 3, "ЗелАО": 3, "ТиНАО": 23}}, "количество_пришедших_заявок": {"type": "Pie", "сумма": 116, "детали": {}}}
25	9	2025-10-01	40	t	{"количество_запросов_в_чат_бот": {"type": "Pie", "сумма": 40, "детали": {}}, "количество_переходов_в_разделы_чат_бота": {"type": "Pie", "сумма": 11, "детали": {"Скачать": 4, "Мобилизация": 0, "Задать вопрос": 0, "Обратная связь": 0, "Кадровая служба": 3, "Деятельность ГИН": 1, "Бухгалтерия для ГГС": 0, "Корпоративная культура": 1, "Обеспечение деятельности": 0, "Противодействие коррупции": 2}}, "количество_активных_пользователей_за_месяц": {"type": "Pie", "сумма": 7, "детали": {}}}
20	7	2025-11-01	472	t	{"география_запросов": {"type": "Bar", "сумма": 472, "детали": {"ВАО": 29, "ЗАО": 50, "САО": 32, "ЦАО": 65, "ЮАО": 25, "СВАО": 36, "СЗАО": 39, "ЮВАО": 55, "ЮЗАО": 24, "ЗелАО": 19, "ТиНАО": 95, "Все округа": 1}}, "количество_пришедших_заявок": {"type": "Pie", "сумма": 472, "детали": {}}}
26	9	2025-11-01	21	t	{"количество_запросов_в_чат_бот": {"type": "Pie", "сумма": 21, "детали": {}}, "количество_переходов_в_разделы_чат_бота": {"type": "Pie", "сумма": 5, "детали": {"Скачать": 2, "Мобилизация": 0, "Задать вопрос": 0, "Обратная связь": 0, "Кадровая служба": 2, "Деятельность ГИН": 1, "Бухгалтерия для ГГС": 0, "Корпоративная культура": 0, "Обеспечение деятельности": 0, "Противодействие коррупции": 0}}, "количество_активных_пользователей_за_месяц": {"type": "Pie", "сумма": 3, "детали": {}}}
27	9	2025-12-01	64	t	{"количество_запросов_в_чат_бот": {"type": "Pie", "сумма": 64, "детали": {}}, "количество_переходов_в_разделы_чат_бота": {"type": "Pie", "сумма": 21, "детали": {"Скачать": 4, "Мобилизация": 0, "Задать вопрос": 3, "Обратная связь": 0, "Кадровая служба": 7, "Деятельность ГИН": 3, "Бухгалтерия для ГГС": 1, "Корпоративная культура": 0, "Обеспечение деятельности": 2, "Противодействие коррупции": 1}}, "количество_активных_пользователей_за_месяц": {"type": "Pie", "сумма": 9, "детали": {}}}
28	10	2025-10-01	1895	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 50, "детали": {"Неверно указан КН": 19, "Найдено несколько адресов": 17, "Введен КН, не принадлежащий Москве и МО": 14}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 1895, "детали": {}}, "информация_по_объектам_не_найдена": {"type": "Pie", "сумма": 815, "детали": {}}, "кол_во_обратившихся_пользователей": {"type": "Pie", "сумма": 93, "детали": {}}, "подтверждены_признаки_самовольного_строительства": {"type": "Pie", "сумма": 1025, "детали": {}}, "направление_заявок_об_объектах_самовольного_строительства_в_аис_гин": {"type": "Pie", "сумма": 5, "детали": {"Создано": 5}}}
29	10	2025-11-01	1264	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 32, "детали": {"Неверно указан КН": 12, "Найдено несколько адресов": 5, "Введен КН, не принадлежащий Москве и МО": 15}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 1264, "детали": {}}, "информация_по_объектам_не_найдена": {"type": "Pie", "сумма": 452, "детали": {}}, "кол_во_обратившихся_пользователей": {"type": "Pie", "сумма": 90, "детали": {}}, "подтверждены_признаки_самовольного_строительства": {"type": "Pie", "сумма": 771, "детали": {}}, "направление_заявок_об_объектах_самовольного_строительства_в_аис_гин_ошибки_при_создании_задач_в_аис_гин": {"type": "Pie", "сумма": 9, "детали": {"Ошибки": 5, "Создано": 4}}}
21	7	2025-12-01	628	t	{"география_запросов": {"type": "Bar", "сумма": 628, "детали": {"ВАО": 39, "ЗАО": 44, "САО": 53, "ЦАО": 82, "ЮАО": 41, "СВАО": 74, "СЗАО": 32, "ЮВАО": 63, "ЮЗАО": 33, "ЗелАО": 28, "ТиНАО": 137, "Все округа": 1}}, "количество_пришедших_заявок": {"type": "Pie", "сумма": 628, "детали": {}}}
22	8	2025-10-01	42	t	{"запросы_по_округам": {"type": "Bar", "сумма": 42, "детали": {"ВАО": 2, "ЗАО": 1, "САО": 5, "ЦАО": 3, "ЮАО": 1, "СВАО": 3, "СЗАО": 1, "ЮЗАО": 2, "ТинАО": 5, "Номер не найден": 19}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 42, "детали": {}}, "количество_новых_пользователей_за_период": {"type": "Pie", "сумма": 16, "детали": {}}}
23	8	2025-11-01	256	t	{"запросы_по_округам": {"type": "Bar", "сумма": 256, "детали": {"ВАО": 55, "ЗАО": 4, "САО": 35, "ЦАО": 17, "ЮАО": 11, "СВАО": 31, "СЗАО": 23, "ЮВАО": 23, "ЮЗАО": 14, "ТинАО": 2, "Номер не найден": 41}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 256, "детали": {}}, "количество_новых_пользователей_за_период": {"type": "Pie", "сумма": 63, "детали": {}}}
24	8	2025-12-01	151	t	{"запросы_по_округам": {"type": "Bar", "сумма": 151, "детали": {"ВАО": 26, "ЗАО": 4, "САО": 16, "ЦАО": 21, "ЮАО": 9, "СВАО": 13, "СЗАО": 6, "ЮВАО": 23, "ЮЗАО": 15, "Номер не найден": 18}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 151, "детали": {}}, "количество_новых_пользователей_за_период": {"type": "Pie", "сумма": 42, "детали": {}}}
11	4	2025-11-01	544	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 260, "детали": {"Нет документов с контрольной датой": 216, "Исполнитель не найден в файле \\"По контролям направлять.xlsx\\"": 44}}, "количество_обработанных_исполнителей": {"type": "Pie", "сумма": 544, "детали": {}}}
12	4	2025-12-01	590	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 229, "детали": {"Нет документов с контрольной датой": 189, "Исполнитель не найден в файле \\"По контролям направлять.xlsx\\"": 40}}, "количество_обработанных_исполнителей": {"type": "Pie", "сумма": 590, "детали": {}}}
30	10	2025-12-01	1164	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 41, "детали": {"Неверно указан КН": 8, "Найдено несколько адресов": 27, "Введен КН, не принадлежащий Москве и МО": 6}}, "количество_запросов_за_месяц": {"type": "Pie", "сумма": 1164, "детали": {}}, "информация_по_объектам_не_найдена": {"type": "Pie", "сумма": 380, "детали": {}}, "кол_во_обратившихся_пользователей": {"type": "Pie", "сумма": 79, "детали": {}}, "подтверждены_признаки_самовольного_строительства": {"type": "Pie", "сумма": 739, "детали": {}}, "направление_заявок_об_объектах_самовольного_строительства_в_аис_гин_ошибки_при_создании_задач_в_аис_гин": {"type": "Pie", "сумма": 4, "детали": {"Ошибки": 1, "Создано": 3}}}
34	12	2025-10-01	30	t	{"география_запросов": {"type": "Bar", "сумма": 30, "детали": {"ВАО": 2, "САО": 2, "ЦАО": 3, "ЮАО": 3, "СЗАО": 14, "ЮВАО": 5, "ЮЗАО": 1}}, "количество_новых_заявок": {"type": "Pie", "сумма": 30, "детали": {}}, "количество_пользователей": {"type": "Pie", "сумма": 27, "детали": {}}, "количество_созданных_задач_в_аис_гин": {"type": "Pie", "сумма": 30, "детали": {}}}
33	11	2025-12-01	7822	t	{"основные_категории_запросов": {"сумма": 7822, "детали": {"type": "Pie", "Вопрос-ответ": 355, "Обратная связь": 20, "Законодательство": 63, "Список неплательщиков": 179, "Новости. Факты. Информация": 120, "Расчет ставки торгового сбора": 7085}}, "количество_новых_заявок_пользователей": {"type": "Pie", "сумма": 8157, "детали": {"Новых заявок": 7822, "Новых пользователей": 335}}, "количество_успешных_расчетов_торгового_сбора": {"type": "Table", "сумма": 658, "детали": {"Общая сумма": 329, "Торговая площадь": 328, "Земельные участки": 1}}}
35	12	2025-11-01	122	t	{"география_запросов": {"type": "Bar", "сумма": 122, "детали": {"ВАО": 21, "ЗАО": 8, "САО": 19, "ЦАО": 15, "ЮАО": 21, "СВАО": 10, "СЗАО": 13, "ЮВАО": 4, "ЮЗАО": 5, "ТиНАО": 6}}, "количество_новых_заявок": {"type": "Pie", "сумма": 122, "детали": {}}, "количество_пользователей": {"type": "Pie", "сумма": 106, "детали": {}}, "количество_созданных_задач_в_аис_гин": {"type": "Pie", "сумма": 85, "детали": {}}, "выявленные_ошибки_при_создании_задачи_в_аис_гин": {"type": "Pie", "сумма": 37, "детали": {}}}
36	12	2025-12-01	86	t	{"география_запросов": {"type": "Bar", "сумма": 86, "детали": {"ВАО": 8, "ЗАО": 10, "САО": 14, "ЦАО": 18, "ЮАО": 4, "СВАО": 4, "СЗАО": 9, "ЮВАО": 7, "ЮЗАО": 3, "ТиНАО": 9}}, "количество_новых_заявок": {"type": "Pie", "сумма": 86, "детали": {}}, "количество_пользователей": {"type": "Pie", "сумма": 73, "детали": {}}, "количество_созданных_задач_в_аис_гин": {"type": "Pie", "сумма": 86, "детали": {}}, "выявленные_ошибки_при_создании_задачи_в_аис_гин": {"type": "Pie", "сумма": 0, "детали": {}}}
4	2	2025-10-01	733	t	{"проверенные_субъекты": {"type": "Pie", "сумма": 733, "детали": {"ИП": 3, "ФЛ": 92, "ЮЛ": 332, "Не определено": 306}}, "выгружено_проверок_из_аис_гин": {"type": "Pie", "сумма": 733, "детали": {}}, "количество_выявленных_статусов_организаций": {"type": "Table", "сумма": 733, "детали": {"Действующее": 235, "Не определено": 491, "Юридическое лицо находится в процессе уменьшения уставного капитала": 2, "Юридическое лицо находится в процессе реорганизации в форме присоединения к другому юридическому лицу": 2, "Юридическое лицо находится в процессе реорганизации в форме присоединения к нему других юридических лиц": 1, "Юридическое лицо признано несостоятельным (банкротом) и в отношении него открыто конкурсное производство": 2}}}
5	2	2025-11-01	1879	t	{"проверенные_субъекты": {"type": "Pie", "сумма": 2040, "детали": {"ИП": 15, "ФЛ": 408, "ЮЛ": 1061, "Не определено": 556}}, "выгружено_проверок_из_аис_гин": {"type": "Pie", "сумма": 1879, "детали": {}}, "количество_выявленных_статусов_организаций": {"type": "Table", "сумма": 1879, "детали": {"Действующее": 724, "Не определено": 1134, "Ликвидировано": 1, "Находится в стадии ликвидации": 2, "Юридическое лицо находится в процессе реорганизации в форме выделения": 9, "Юридическое лицо находится в процессе реорганизации в форме преобразования": 1, "В отношении юридического лица в деле о несостоятельности (банкротстве) введено наблюдение": 1, "Юридическое лицо находится в процессе реорганизации в форме присоединения к другому юридическому лицу": 1, "Юридическое лицо находится в процессе реорганизации в форме присоединения к нему других юридических лиц": 6}}}
6	2	2025-12-01	1175	t	{"проверенные_субъекты": {"type": "Pie", "сумма": 1317, "детали": {"ИП": 18, "ФЛ": 305, "ЮЛ": 808, "Не определено": 186}}, "выгружено_проверок_из_аис_гин": {"type": "Pie", "сумма": 1175, "детали": {}}, "количество_выявленных_статусов_организаций": {"type": "Table", "сумма": 1175, "детали": {"Действующее": 533, "Не определено": 636, "Находится в стадии ликвидации": 1, "Юридическое лицо признано несостоятельным (банкротом) и в отношении него открыто конкурсное производство": 5}}}
13	5	2025-10-01	294	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 187, "детали": {"Среди исходящих(не удалось проставить штампы)": 187}}, "отправитель_входящих_документов": {"type": "Bar", "сумма": 81, "детали": {"ДКН": 6, "ДЖКХ": 4, "КГСН": 14, "МБТИ": 20, "ОАТИ": 6, "КпАиГ": 25, "ДПиООС": 6}}, "количество_зарегистрированных_телеграмм": {"type": "Pie", "сумма": 21, "детали": {"Зарегистрировано входящих": 0, "Зарегистрировано исходящих": 21}}, "количество_зарегистрированных_документов": {"type": "Pie", "сумма": 273, "детали": {"Зарегистрировано входящих": 81, "Зарегистрировано исходящих": 187, "Зарегистрировано внутренних": 5}}}
14	5	2025-11-01	967	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 683, "детали": {"Среди исходящих(не удалось проставить штампы)": 683}}, "отправитель_входящих_документов": {"type": "Bar", "сумма": 264, "детали": {"ДКН": 30, "ДЖКХ": 6, "КГСН": 25, "МБТИ": 95, "ОАТИ": 21, "КпАиГ": 69, "ДПиООС": 18}}, "количество_зарегистрированных_телеграмм": {"type": "Pie", "сумма": 82, "детали": {"Зарегистрировано входящих": 0, "Зарегистрировано исходящих": 82}}, "количество_зарегистрированных_документов": {"type": "Pie", "сумма": 967, "детали": {"Зарегистрировано входящих": 264, "Зарегистрировано исходящих": 683, "Зарегистрировано внутренних": 20}}}
15	5	2025-12-01	1378	t	{"выявленные_ошибки": {"type": "Pie", "сумма": 958, "детали": {"Среди исходящих(не удалось проставить штампы)": 958}}, "отправитель_входящих_документов": {"type": "Bar", "сумма": 394, "детали": {"ДКН": 20, "ДЖКХ": 7, "КГСН": 20, "МБТИ": 142, "ОАТИ": 36, "КпАиГ": 133, "ДПиООС": 36}}, "количество_зарегистрированных_телеграмм": {"type": "Pie", "сумма": 120, "детали": {"Не найден адрес или адресат": 1, "Зарегистрировано исходящих": 119}}, "количество_зарегистрированных_документов": {"type": "Pie", "сумма": 1378, "детали": {"Зарегистрировано входящих": 394, "Зарегистрировано исходящих": 958, "Зарегистрировано внутренних": 26}}}
31	11	2025-10-01	829	t	{"основные_категории_запросов": {"type": "Pie", "сумма": 829, "детали": {"Вопрос-ответ": 48, "Обратная связь": 4, "Законодательство": 24, "Список неплательщиков": 62, "Новости. Факты. Информация": 31, "Расчет ставки торгового сбора": 660}}, "количество_новых_заявок_пользователей": {"type": "Pie", "сумма": 881, "детали": {"Новых заявок": 829, "Новых пользователей": 52}}, "количество_успешных_расчетов_торгового_сбора": {"type": "Table", "сумма": 70, "детали": {"Общая сумма": 35, "Торговая площадь": 33, "Объекты капитального строительства площадями 120, 80": 1, "Площади земельных участков и объектов капительного строительства площадью 500 м²": 1}}}
32	11	2025-11-01	4227	t	{"основные_категории_запросов": {"сумма": 4227, "детали": {"type": "Pie", "Вопрос-ответ": 356, "Обратная связь": 11, "Законодательство": 42, "Список неплательщиков": 231, "Новости. Факты. Информация": 100, "Расчет ставки торгового сбора": 3487}}, "количество_новых_заявок_пользователей": {"type": "Pie", "сумма": 4464, "детали": {"Новых заявок": 4227, "Новых пользователей": 237}}, "количество_успешных_расчетов_торгового_сбора": {"type": "Table", "сумма": 290, "детали": {"Общая сумма": 145, "Торговая площадь": 142, "Площади земельных участков и объектов капитального строительства площадью 80 м²": 1, "Площади замельных участков и объектов капитального строительства площадами 12 м²": 1, "Площади земельных участков и объектов капитального строительства площадью 120, 89 м²": 1}}}
\.


--
-- TOC entry 5069 (class 0 OID 16539)
-- Dependencies: 238
-- Data for Name: robots_apartaments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.robots_apartaments (id, date_start, worked_out_by_the_algorithm, doubles, violations_detected_by_the_algorithm, no_violations_were_detected, vri_was_not_found, count_transferred_ka, is_transferred_to_ka, date_transferred, date_receipt, total_objects_worked_out, confirmed_violations_new, confirmed_violations_previously, comment, object_id) FROM stdin;
1	2025-11-18	176	33	142	120	1	0	t	2025-11-19	2025-11-25	142	1	0		1
2	2025-11-26	2000	907	755	292	3	0	t	2025-11-27	2025-10-01	755	5	0		2
3	2025-12-15	3716	0	383	2865	468	0	t	2025-12-19	2026-01-13	303	16	46		3
4	2025-11-13	4390	3653	496	0	2	496	t	2025-11-18	2025-11-25	0	0	0		4
\.


--
-- TOC entry 5079 (class 0 OID 16654)
-- Dependencies: 248
-- Data for Name: sourse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sourse (id, source) FROM stdin;
1	обесцвечение
2	парцелла
3	кисловка
4	низкопоклонник
5	балетоман
6	судейская
7	подземелье
8	ковкость
9	эвакопункт
10	флюгерство
\.


--
-- TOC entry 5057 (class 0 OID 16420)
-- Dependencies: 226
-- Data for Name: statusapplication; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statusapplication (id, name) FROM stdin;
2	ДУБЛЬ
1	ИСПОЛНЕНА
3	НА ИСПОЛНЕНИИ В ДИТ
5	НЕАКТУАЛЬНА
4	ОТМЕНЕНА КАК ДУБЛЬ
\.


--
-- TOC entry 5073 (class 0 OID 16620)
-- Dependencies: 242
-- Data for Name: type_photo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.type_photo (id, name) FROM stdin;
1	БПЛА
2	ЕЦХД
3	КОСМОС
4	КИНС
\.


--
-- TOC entry 5055 (class 0 OID 16412)
-- Dependencies: 224
-- Data for Name: violations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.violations (id, name) FROM stdin;
4	1255-ПП до 01.09.2024
9	1255-ПП после 01.09.2024 г. 
14	6.11 Использование ЗУ с нарушением требований к оформлению документов
7	819-ПП - Нецелевое использование ЗУ
6	Ветхий
3	Захламление территории 
1	Нет
5	Ограничение доступа на ЗУ
8	Отсутствие ЗПО
2	Самовольное строительство
10	ст. 6.7 ч.1.2 Самовольное строительство без РС 
\.


--
-- TOC entry 5081 (class 0 OID 16715)
-- Dependencies: 250
-- Data for Name: work_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_progress (id, id_sourse, all_perimeter, complete_perimeter, remained_perimeter, created_at, comment) FROM stdin;
1	1	100	60	40	2026-04-12 03:25:22.480324	
\.


--
-- TOC entry 5083 (class 0 OID 16731)
-- Dependencies: 252
-- Data for Name: work_progress_violations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_progress_violations (id, id_work_progress, id_article, object_a_week, new_violations, old_violations) FROM stdin;
1	1	1	10	3	7
\.


--
-- TOC entry 5106 (class 0 OID 0)
-- Dependencies: 221
-- Name: addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.addresses_id_seq', 1, false);


--
-- TOC entry 5107 (class 0 OID 0)
-- Dependencies: 243
-- Name: article_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_id_seq', 1, false);


--
-- TOC entry 5108 (class 0 OID 0)
-- Dependencies: 239
-- Name: bpla_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bpla_id_seq', 1, false);


--
-- TOC entry 5109 (class 0 OID 0)
-- Dependencies: 219
-- Name: districts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.districts_id_seq', 1, false);


--
-- TOC entry 5110 (class 0 OID 0)
-- Dependencies: 245
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 1, false);


--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 235
-- Name: objects_for_apartmens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.objects_for_apartmens_id_seq', 1, false);


--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 227
-- Name: overfly_block1_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.overfly_block1_id_seq', 1, false);


--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 229
-- Name: overfly_block2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.overfly_block2_id_seq', 1, false);


--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 233
-- Name: robots_analitic_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.robots_analitic_id_seq', 1, false);


--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 237
-- Name: robots_apartaments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.robots_apartaments_id_seq', 1, false);


--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 231
-- Name: robots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.robots_id_seq', 1, false);


--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 247
-- Name: source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.source_id_seq', 1, false);


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 225
-- Name: statusapplication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.statusapplication_id_seq', 1, false);


--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 241
-- Name: type_photo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.type_photo_id_seq', 1, false);


--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 223
-- Name: violations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.violations_id_seq', 1, true);


--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 249
-- Name: work_progress_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_progress_id_seq', 1, true);


--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 251
-- Name: work_progress_violations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_progress_violations_id_seq', 1, true);


--
-- TOC entry 4859 (class 2606 OID 16410)
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- TOC entry 4883 (class 2606 OID 16643)
-- Name: article article_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article
    ADD CONSTRAINT article_pkey PRIMARY KEY (id);


--
-- TOC entry 4879 (class 2606 OID 16596)
-- Name: photos bpla_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT bpla_pkey PRIMARY KEY (id);


--
-- TOC entry 4857 (class 2606 OID 16400)
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- TOC entry 4885 (class 2606 OID 16651)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- TOC entry 4875 (class 2606 OID 16535)
-- Name: objects_for_apartmens objects_for_apartmens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.objects_for_apartmens
    ADD CONSTRAINT objects_for_apartmens_pkey PRIMARY KEY (id);


--
-- TOC entry 4865 (class 2606 OID 16434)
-- Name: overfly_block1 overfly_block1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block1
    ADD CONSTRAINT overfly_block1_pkey PRIMARY KEY (id);


--
-- TOC entry 4868 (class 2606 OID 16457)
-- Name: overfly_block2 overfly_block2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block2
    ADD CONSTRAINT overfly_block2_pkey PRIMARY KEY (id);


--
-- TOC entry 4873 (class 2606 OID 16518)
-- Name: robots_analitic robots_analitic_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_analitic
    ADD CONSTRAINT robots_analitic_pkey PRIMARY KEY (id);


--
-- TOC entry 4877 (class 2606 OID 16547)
-- Name: robots_apartaments robots_apartaments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_apartaments
    ADD CONSTRAINT robots_apartaments_pkey PRIMARY KEY (id);


--
-- TOC entry 4871 (class 2606 OID 16500)
-- Name: robots robots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots
    ADD CONSTRAINT robots_pkey PRIMARY KEY (id);


--
-- TOC entry 4887 (class 2606 OID 16660)
-- Name: sourse source_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sourse
    ADD CONSTRAINT source_pkey PRIMARY KEY (id);


--
-- TOC entry 4863 (class 2606 OID 16426)
-- Name: statusapplication statusapplication_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statusapplication
    ADD CONSTRAINT statusapplication_pkey PRIMARY KEY (id);


--
-- TOC entry 4881 (class 2606 OID 16626)
-- Name: type_photo type_photo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_photo
    ADD CONSTRAINT type_photo_pkey PRIMARY KEY (id);


--
-- TOC entry 4861 (class 2606 OID 16418)
-- Name: violations violations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.violations
    ADD CONSTRAINT violations_pkey PRIMARY KEY (id);


--
-- TOC entry 4889 (class 2606 OID 16724)
-- Name: work_progress work_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress
    ADD CONSTRAINT work_progress_pkey PRIMARY KEY (id);


--
-- TOC entry 4891 (class 2606 OID 16737)
-- Name: work_progress_violations work_progress_violations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress_violations
    ADD CONSTRAINT work_progress_violations_pkey PRIMARY KEY (id);


--
-- TOC entry 4866 (class 1259 OID 16779)
-- Name: fki_fk_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_fk_status ON public.overfly_block2 USING btree (id_status);


--
-- TOC entry 4869 (class 1259 OID 16790)
-- Name: indx_robot_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX indx_robot_name ON public.robots USING btree (name);


--
-- TOC entry 4892 (class 2606 OID 16440)
-- Name: overfly_block1 fk_adress; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block1
    ADD CONSTRAINT fk_adress FOREIGN KEY (idadress) REFERENCES public.addresses(id) ON DELETE SET NULL;


--
-- TOC entry 4895 (class 2606 OID 16463)
-- Name: overfly_block2 fk_adress2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block2
    ADD CONSTRAINT fk_adress2 FOREIGN KEY (id_adress) REFERENCES public.addresses(id) ON DELETE SET NULL;


--
-- TOC entry 4893 (class 2606 OID 16435)
-- Name: overfly_block1 fk_distric; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block1
    ADD CONSTRAINT fk_distric FOREIGN KEY (iddistric) REFERENCES public.districts(id) ON DELETE SET NULL;


--
-- TOC entry 4896 (class 2606 OID 16458)
-- Name: overfly_block2 fk_distric2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block2
    ADD CONSTRAINT fk_distric2 FOREIGN KEY (id_distric) REFERENCES public.districts(id) ON DELETE SET NULL;


--
-- TOC entry 4898 (class 2606 OID 16519)
-- Name: robots_analitic fk_robotsanalityc_robot; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_analitic
    ADD CONSTRAINT fk_robotsanalityc_robot FOREIGN KEY (idrobots) REFERENCES public.robots(id);


--
-- TOC entry 4897 (class 2606 OID 16780)
-- Name: overfly_block2 fk_status; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block2
    ADD CONSTRAINT fk_status FOREIGN KEY (id_status) REFERENCES public.statusapplication(id) NOT VALID;


--
-- TOC entry 4894 (class 2606 OID 16445)
-- Name: overfly_block1 fk_violation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overfly_block1
    ADD CONSTRAINT fk_violation FOREIGN KEY (idviolation) REFERENCES public.violations(id) ON DELETE SET NULL;


--
-- TOC entry 4900 (class 2606 OID 16627)
-- Name: photos photos_photos_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT photos_photos_fk FOREIGN KEY (id_type) REFERENCES public.photos(id);


--
-- TOC entry 4899 (class 2606 OID 16548)
-- Name: robots_apartaments robots_apartaments_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.robots_apartaments
    ADD CONSTRAINT robots_apartaments_object_id_fkey FOREIGN KEY (object_id) REFERENCES public.objects_for_apartmens(id) ON DELETE SET NULL;


--
-- TOC entry 4901 (class 2606 OID 16725)
-- Name: work_progress work_progress_id_sourse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress
    ADD CONSTRAINT work_progress_id_sourse_fkey FOREIGN KEY (id_sourse) REFERENCES public.sourse(id);


--
-- TOC entry 4902 (class 2606 OID 16738)
-- Name: work_progress_violations work_progress_violations_id_work_progress_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_progress_violations
    ADD CONSTRAINT work_progress_violations_id_work_progress_fkey FOREIGN KEY (id_work_progress) REFERENCES public.work_progress(id);


-- Completed on 2026-04-28 23:28:59

--
-- PostgreSQL database dump complete
--

\unrestrict 1jYB01UbrnadBlcUXjxivAg29GYLZaMIlhfzLYRM7Rvv1kFkqeLDmaH2DpflkYH

