--
-- PostgreSQL database dump
--

\restrict OEKbJsTIoiCMibmgcyVtxiUSERzdZ8RmHTjXrgkyS1YX3S1WWXgJ2gcY7OF1zp7

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AspNetRoles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."AspNetRoles" (
    "Id" text NOT NULL,
    "Name" character varying(256),
    "NormalizedName" character varying(256),
    "ConcurrencyStamp" text
);


ALTER TABLE public."AspNetRoles" OWNER TO postgres;

--
-- Name: AspNetUserRoles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."AspNetUserRoles" (
    "UserId" text NOT NULL,
    "RoleId" text NOT NULL
);


ALTER TABLE public."AspNetUserRoles" OWNER TO postgres;

--
-- Name: AspNetUsers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."AspNetUsers" (
    "Id" text NOT NULL,
    "FullName" text,
    "Department" text,
    "CreatedAt" timestamp with time zone DEFAULT now(),
    "IsApproved" boolean DEFAULT false,
    "UserName" character varying(256),
    "NormalizedUserName" character varying(256),
    "Email" character varying(256),
    "NormalizedEmail" character varying(256),
    "EmailConfirmed" boolean DEFAULT false,
    "PasswordHash" text,
    "SecurityStamp" text,
    "ConcurrencyStamp" text,
    "PhoneNumber" text,
    "PhoneNumberConfirmed" boolean DEFAULT false,
    "TwoFactorEnabled" boolean DEFAULT false,
    "LockoutEnd" timestamp with time zone,
    "LockoutEnabled" boolean DEFAULT false,
    "AccessFailedCount" integer DEFAULT 0
);


ALTER TABLE public."AspNetUsers" OWNER TO postgres;

--
-- Name: ChatMessages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ChatMessages" (
    "Id" integer NOT NULL,
    "UserId" text,
    "UserName" text,
    "Message" text,
    "CreatedAt" timestamp without time zone DEFAULT now()
);


ALTER TABLE public."ChatMessages" OWNER TO postgres;

--
-- Name: ChatMessages_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ChatMessages_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ChatMessages_Id_seq" OWNER TO postgres;

--
-- Name: ChatMessages_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ChatMessages_Id_seq" OWNED BY public."ChatMessages"."Id";


--
-- Name: EventLogs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."EventLogs" (
    "Id" integer NOT NULL,
    "UserId" text,
    "Action" text,
    "Description" text,
    "CreatedAt" timestamp with time zone DEFAULT now()
);


ALTER TABLE public."EventLogs" OWNER TO postgres;

--
-- Name: EventLogs_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."EventLogs_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."EventLogs_Id_seq" OWNER TO postgres;

--
-- Name: EventLogs_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."EventLogs_Id_seq" OWNED BY public."EventLogs"."Id";


--
-- Name: UserEvents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UserEvents" (
    "Id" integer NOT NULL,
    "UserId" text,
    "Title" text NOT NULL,
    "Description" text,
    "EventDate" timestamp with time zone NOT NULL,
    "Color" text DEFAULT '#1976d2'::text,
    "CreatedAt" timestamp with time zone DEFAULT now()
);


ALTER TABLE public."UserEvents" OWNER TO postgres;

--
-- Name: UserEvents_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."UserEvents_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."UserEvents_Id_seq" OWNER TO postgres;

--
-- Name: UserEvents_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."UserEvents_Id_seq" OWNED BY public."UserEvents"."Id";


--
-- Name: ChatMessages Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ChatMessages" ALTER COLUMN "Id" SET DEFAULT nextval('public."ChatMessages_Id_seq"'::regclass);


--
-- Name: EventLogs Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EventLogs" ALTER COLUMN "Id" SET DEFAULT nextval('public."EventLogs_Id_seq"'::regclass);


--
-- Name: UserEvents Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserEvents" ALTER COLUMN "Id" SET DEFAULT nextval('public."UserEvents_Id_seq"'::regclass);


--
-- Data for Name: AspNetRoles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."AspNetRoles" ("Id", "Name", "NormalizedName", "ConcurrencyStamp") FROM stdin;
admin-001	Admin	ADMIN	
editor-001	Editor	EDITOR	
viewer-001	Viewer	VIEWER	
\.


--
-- Data for Name: AspNetUserRoles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."AspNetUserRoles" ("UserId", "RoleId") FROM stdin;
\.


--
-- Data for Name: AspNetUsers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."AspNetUsers" ("Id", "FullName", "Department", "CreatedAt", "IsApproved", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumber", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnd", "LockoutEnabled", "AccessFailedCount") FROM stdin;
\.


--
-- Data for Name: ChatMessages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ChatMessages" ("Id", "UserId", "UserName", "Message", "CreatedAt") FROM stdin;
\.


--
-- Data for Name: EventLogs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."EventLogs" ("Id", "UserId", "Action", "Description", "CreatedAt") FROM stdin;
\.


--
-- Data for Name: UserEvents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."UserEvents" ("Id", "UserId", "Title", "Description", "EventDate", "Color", "CreatedAt") FROM stdin;
\.


--
-- Name: ChatMessages_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ChatMessages_Id_seq"', 1, false);


--
-- Name: EventLogs_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."EventLogs_Id_seq"', 1, false);


--
-- Name: UserEvents_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."UserEvents_Id_seq"', 1, false);


--
-- Name: AspNetRoles AspNetRoles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AspNetRoles"
    ADD CONSTRAINT "AspNetRoles_pkey" PRIMARY KEY ("Id");


--
-- Name: AspNetUserRoles AspNetUserRoles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "AspNetUserRoles_pkey" PRIMARY KEY ("UserId", "RoleId");


--
-- Name: AspNetUsers AspNetUsers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AspNetUsers"
    ADD CONSTRAINT "AspNetUsers_pkey" PRIMARY KEY ("Id");


--
-- Name: ChatMessages ChatMessages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ChatMessages"
    ADD CONSTRAINT "ChatMessages_pkey" PRIMARY KEY ("Id");


--
-- Name: EventLogs EventLogs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EventLogs"
    ADD CONSTRAINT "EventLogs_pkey" PRIMARY KEY ("Id");


--
-- Name: UserEvents UserEvents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserEvents"
    ADD CONSTRAINT "UserEvents_pkey" PRIMARY KEY ("Id");


--
-- Name: AspNetUserRoles AspNetUserRoles_RoleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "AspNetUserRoles_RoleId_fkey" FOREIGN KEY ("RoleId") REFERENCES public."AspNetRoles"("Id");


--
-- Name: AspNetUserRoles AspNetUserRoles_UserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "AspNetUserRoles_UserId_fkey" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id");


--
-- PostgreSQL database dump complete
--

\unrestrict OEKbJsTIoiCMibmgcyVtxiUSERzdZ8RmHTjXrgkyS1YX3S1WWXgJ2gcY7OF1zp7

