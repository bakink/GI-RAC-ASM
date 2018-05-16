declare
    policy_admin_link_mail_subject constant varchar2(100) := 'Allianz Kurumsal Saðlýk Portal Yöneticisi Link Gönderimi';

    policy_admin_link_mail_body    constant varchar2(4000):= '%%name%% %%surname%% <br><br/>'
                                                          || 'Allianz Sigorta Online Grup Saðlýk Ýþlemleri sayfasýnýn yenilenmesiyle, yeni yapýda Portal Yöneticisi olarak atandýnýz.<br/>'
                                                          || 'Yeni yapýda atanmýþ olduðunuz statünün yetkinlikleri ile ilgili <a href=https://adf.allianz.com.tr/GroupHealthPortalWeb/resources/docs/guncelleme_detayi_sss.pdf>Tanýmlar ve Sýkça Sorulan Sorular dökümanýný indirebilirsiniz.</a><br/>'
                                                          || 'Atanmýþ olduðunuz <b><u>Portal Yöneticisi</u></b> statüsü için size özel yeni bir kullanýcý adý oluþturulmuþ ve aþaðýda paylaþýlmýþtýr.<br/>'
                                                          || 'Eski yapýda kullanmýþ olduðunuz kullanýcý adý ve þifrenizle ilgili bilgilendirme maili iletilecektir, eski kullanýcý adýnýzýn baþýna W harfini ekleyerek sisteme giriþinizden sonra Poliçe Ýþlem Yetkilisi iþlemlerine devam edebilirsiniz.<br><br/>'
                                                          || 'Portal Yöneticisi kullanýcýnýza özel þifre oluþturmak için <a href=%%UW_COMPANY_REP_USER_LINK%%%%token%%>baglanti adresine tiklayabilirsiniz.</a>'
                                                          || 'Þifrenizi oluþturduktan sonra Poliçe Ýþlemleri Yetkilisi atamalarýný yapabilirsiniz.<br/>'
                                                          || 'Portal Yöneticisi Kullanýcý Adýnýz: %%username%%<br><br/>'
                                                          || 'Saygilarimizla,<br><br/>Allianz Sigorta A.S.';
                                                  
    policy_user_link_mail_subject constant varchar2(100)  := 'Allianz Kurumsal Saðlýk Poliçe Ýþlem Yetkilisi Link Gönderimi';

    policy_user_link_mail_body    constant varchar2(4000) := '%%name%% %%surname%% <br><br/>'
                                                          || 'Allianz Sigorta Online Grup Saðlýk Ýþlemleri sayfasýnýn yenilenmesiyle, yeni yapýda Poliçe Ýþlem Yetkilisi olarak atandýnýz.<br/>'
                                                          || 'Yeni yapýda atanmýþ olduðunuz statünün yetkinlikleri ile ilgili <a href=https://adf.allianz.com.tr/GroupHealthPortalWeb/resources/docs/guncelleme_detayi_sss.pdf>Tanýmlar ve Sýkça Sorulan Sorular dökümanýný indirebilirsiniz.</a><br/>'
                                                          || 'Atanmýþ olduðunuz <b><u>Poliçe Ýþlem Yetkilisi</u></b> statüsü için yeni bir kullanýcý adý oluþturulmamýþtýr, aþaðýdaki talimatlar doðrultusunda portal giriþinizi yapabilirsiniz.<br/>'
                                                          || 'Eski yapýda kullanmýþ oldðunuz kullanýcý adýnýzýn baþýna <B>W</b> harfini ekleyerek sisteme giriþinizden sonra <u>Poliçe Ýþlem Yetkilisi</u> iþlemlerine devam edebilirsiniz.<br><br/>'
                                                          || 'Aktivasyonunuzu gerçekleþtirmek için <a href=%%UW_COMPANY_REP_USER_LINK%%%%token%%>baðlantý adresine tiklayabilirsiniz.</a>'
                                                          || 'Aktivasyonunuzu gerçekleþtirdikten sonra Poliçe Ýþlemlerinizi yapabilirsiniz.<br/>'
                                                          || 'Poliçe Ýþlem Yetkilisi Kullanici Adiniz: %%username%%<br><br/>'
                                                          || 'Saygilarimizla,<br><br/>Allianz Sigorta A.S.';
                                                          
    v_service_name              Varchar2 (20);
    v_admin_gsm                 ALZ_GHLTH_PORTAL_USER.GSM%TYPE;
    v_portal_user_gsm           ALZ_GHLTH_PORTAL_USER.GSM%TYPE;
    p_created_username          ALZ_GHLTH_PORTAL_USER.USER_NAME%TYPE;
    p_main_group_code           VARCHAR2(100);
    v_portal_user_rel_seq       number;
    v_rel_type                  ALZ_GHLTH_PORTAL_USER.REL_TYPE%TYPE;
    v_auth_role_table           Customer.char_array;
    p_process_results           process_result_table;
    v_enc_policy_user_pass      ALZ_GHLTH_PORTAL_USERS.PASSWORD%TYPE;
    v_count_11159               number := 0;
    v_rel_log_id_seq            number;
    -- mail parameterleri
    v_mail_content              varchar2(32767);
    p_mail                      varchar2(32767);
    v_mail_to                   varchar2(100) := 'extern.mehmetsami-alpak@allianz.com.tr';
    v_Mail_Input                Customer.EuroMsg_Mail_Input_Rec;
    p_Response_Rec              Customer.EuroMsg_Mail_Response_Table:=Customer.EuroMsg_Mail_Response_Table();
    v_String_Rec_to             Customer.String_Table :=customer.String_Table();
    v_Email_Sent                INT;
    v_mail_policy_admin_link    ALZ_GHLTH_PARAMETERS.VALUE%TYPE;
    v_mail_policy_user_link     ALZ_GHLTH_PARAMETERS.VALUE%TYPE;
    p_main_group_code_info      varchar2(10);
begin
    DBMS_OUTPUT.put_line('starting time : '|| TO_CHAR (SYSDATE,'YYYY-MM-DD HH24:MI:SS'));
    p_process_results    := process_result_table();
    
    SELECT value into v_mail_policy_admin_link
    FROM   ALZ_GHLTH_PARAMETERS
    WHERE  NAME = 'UW_COMPANY_REP_USER_LINK';
    
    SELECT value into v_mail_policy_user_link
    FROM   ALZ_GHLTH_PARAMETERS
    WHERE  NAME = 'UW_PORTAL_NEW_USER_LINK';
    
    -- live : OPUSDATA , uat : OPUSDEV, prep : OPUSPREP
    Select Ora_Database_Name 
    Into   v_service_name
    From   Dual;
    
    IF v_service_name = 'OPUSDATA' THEN
        v_admin_gsm       := NULL;
        v_portal_user_gsm := NULL;
    ELSE
        v_admin_gsm       := '5448930062';
        v_portal_user_gsm := '5413635072';
    END IF;
    
    dbms_output.put_line('service name : '||v_service_name);
    
    FOR rec_portal_user_info in(SELECT * FROM GHLTH_PORTAL_USER_EXTRA_LIST@OPUSDEVL WHERE EMAIL IS NOT NULL)
    LOOP
        begin
            select main_group_code into p_main_group_code_info
            from koc_cp_group_master
            where group_code = upper(rec_portal_user_info.group_code)
            and   validity_end_date is null
            and   rownum = 1;
            
            exception when no_data_found then
            p_main_group_code_info := null;
        end;
        
        IF p_main_group_code_info is not null THEN
            begin
                SELECT PASSWORD 
                into   v_enc_policy_user_pass
                FROM   ALZ_GHLTH_PORTAL_USERS
                WHERE  USER_NAME = rec_portal_user_info.USER_NAME
                AND    ROWNUM = 1;
                
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    v_enc_policy_user_pass := NULL;
            end;
            -- IF rec_portal_user_info.USER_NAME in ('GRYTAZ925507', 'GRYTAZ926601', 'GRYTAZ1328401') THEN
            --IF rec_portal_user_info.USER_NAME in ('GRYTAZ1388901', 'GRYTAZ498501', 'GRYTAZ1309101', 'GRYTAZ1309102') THEN
            IF rec_portal_user_info.admin_bilgisi = 1 THEN
                dbms_output.put_line(rec_portal_user_info.USER_NAME);
                dbms_output.put_line('admin kullanicisi olusturulacak');
                p_created_username := 'WA' || rec_portal_user_info.USER_NAME;
                dbms_output.put_line(p_created_username);
                
                -- oncelikle admin kullanici kaydi yapilir.
                INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER PR
                        (PR.USER_NAME,
                         PR.NAME,
                         PR.SURNAME,
                         PR.EMAIL,
                         PR.GSM,
                         PR.REL_TYPE,
                         PR.IS_ADMIN,
                         PR.STATUS,
                         PR.ACTION_CODE,
                         PR.TOKEN,
                         PR.ENC_TOKEN,
                         PR.CREATE_USER,
                         PR.CREATE_DATE)
                 VALUES(p_created_username,
                        rec_portal_user_info.FIRST_NAME,
                        rec_portal_user_info.LAST_NAME,
                        rec_portal_user_info.EMAIL,
                        v_admin_gsm,
                        NULL,
                        1,
                        1,
                        'A',
                        rec_portal_user_info.ADMIN_TOKEN,
                        rec_portal_user_info.ADMIN_TOKEN_ENC,
                        'GHLTH-PORTAL',
                        sysdate);
                
                -- olusturdugumuz kullanicinin yetki kaydi yapilacak.
                IF rec_portal_user_info.description is not null THEN
                    dbms_output.put_line(rec_portal_user_info.description);
                    FOR rec_main_group_info IN (SELECT REGEXP_SUBSTR (rec_portal_user_info.DESCRIPTION,
                                                         '[^;]+',
                                                         1,
                                                         LEVEL) TXT FROM DUAL
                                               CONNECT BY REGEXP_SUBSTR (rec_portal_user_info.DESCRIPTION,
                                                                         '[^;]+',
                                                                         1,
                                                                         LEVEL)
                                                             IS NOT NULL)
                    LOOP
                        p_main_group_code     := trim(rec_main_group_info.txt);
                        dbms_output.put_line('main_group_code : '|| p_main_group_code);
                        v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                   
                        INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                                (RD.ID,
                                 RD.USER_NAME,
                                 RD.MAIN_GROUP_CODE,
                                 RD.CREATE_DATE)
                        VALUES(v_portal_user_rel_seq,
                               p_created_username,
                               p_main_group_code,
                               SYSDATE);
                    END LOOP;
                ELSE
                   -- eger null ise bir tane ust gruba yetki olacak demektir.
                    FOR rec_main_group_info IN (SELECT REGEXP_SUBSTR (rec_portal_user_info.MAIN_GROUP_INFO,
                                                         '[^-]+',
                                                         1,
                                                         LEVEL) TXT FROM DUAL
                                           CONNECT BY REGEXP_SUBSTR (rec_portal_user_info.MAIN_GROUP_INFO,
                                                                     '[^-]+',
                                                                     1,
                                                                     LEVEL)
                                                         IS NOT NULL)
                    LOOP
                        p_main_group_code := trim(rec_main_group_info.txt);
                        dbms_output.put_line('main_group_code : '|| p_main_group_code);
                        exit;
                    END LOOP;
                   
                   v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                   
                   INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                            (RD.ID,
                             RD.USER_NAME,
                             RD.MAIN_GROUP_CODE,
                             RD.CREATE_DATE)
                   VALUES(v_portal_user_rel_seq,
                          p_created_username,
                          p_main_group_code,
                          SYSDATE);
                END IF;
                
                -- simdi web kullanici olusturulup bu kullaniciya rol tanimlamalari yapilacak.
                v_auth_role_table := Customer.char_array();
                v_auth_role_table.extend;
                -- company representative admin
                v_auth_role_table(v_auth_role_table.count) := 'WGSCRADMIN'; 
                v_auth_role_table.extend;
                v_auth_role_table(v_auth_role_table.count) := 'WLOGIN';
                v_auth_role_table.extend;
                v_auth_role_table(v_auth_role_table.count) := 'WPGSPPRTL';
                v_auth_role_table.extend;
                v_auth_role_table(v_auth_role_table.count) := 'WPGSPUSERO';
                    
                ALZ_GHLTH_POLICY_UTILS7.create_web_user_automatically (p_created_username,
                                                                       rec_portal_user_info.FIRST_NAME,
                                                                       rec_portal_user_info.LAST_NAME,
                                                                       null,  -- password sonra set edilecek. kullanici belirleyecek.
                                                                       rec_portal_user_info.EMAIL,
                                                                       NULL,
                                                                       'SYSTEM-GHLTH-PORTAL',
                                                                       v_auth_role_table,
                                                                       p_process_results);
                
                IF rec_portal_user_info.ADMIN_EMAIL_SENT = 0 THEN
                    -- sifre belirleme linki gonderilecek.                               
                    v_mail_content := policy_admin_link_mail_body;
                    v_mail_content := replace(v_mail_content, '%%name%%',     rec_portal_user_info.FIRST_NAME);
                    v_mail_content := replace(v_mail_content, '%%surname%%',  rec_portal_user_info.LAST_NAME);
                    v_mail_content := replace(v_mail_content, '%%UW_COMPANY_REP_USER_LINK%%', v_mail_policy_admin_link);
                    v_mail_content := replace(v_mail_content, '%%token%%',    rec_portal_user_info.ADMIN_TOKEN_ENC);
                    v_mail_content := replace(v_mail_content, '%%username%%', p_created_username);

                    p_mail := '<p><span style=font-family: arial, helvetica, sans-serif; font-size: x-small;>'|| v_mail_content ||'</span></p>';

                    v_String_Rec_to.delete();
                    v_String_Rec_to.extend;
                    IF v_service_name = 'OPUSDATA' THEN
                        v_String_Rec_to(1) := String_Rec(rec_portal_user_info.EMAIL);
                    ELSE
                        v_String_Rec_to(1) := String_Rec('extern.mehmetsami-alpak@allianz.com.tr');    
                    END IF;
                    
                    v_Mail_Input := customer.EuroMsg_Mail_Input_Rec (null,
                                                                     'Template',
                                                                     null,
                                                                     v_String_Rec_to,
                                                                     null,
                                                                     null,
                                                                     policy_admin_link_mail_subject,
                                                                     p_mail,
                                                                     'GROUP_PORTAL_MAIL',
                                                                     null, --v_Report_Parameters,
                                                                     '045',
                                                                     p_created_username,
                                                                     null);
                    Alz_euromsg_utils.Send_Mail(v_Mail_Input,
                                                'GROUP_PORTAL_MAIL',
                                                p_Response_Rec,
                                                p_Process_Results);

                    v_Email_Sent := 0;

                    FOR i IN 1 .. p_Response_Rec.COUNT
                    LOOP
                         If  v_Email_Sent = 0
                             and p_Response_Rec(i).Hata_Code = '200'
                             and lower(p_Response_Rec(i).Response_Name) = 'code'
                             and p_Response_Rec(i).Response_Value = '0' then
                         --Mail Gönderimi baþarýlý
                         v_Email_Sent := 1;
                     End if;
                    END LOOP;

                    IF v_Email_Sent = 1 THEN
                       -- link maili gonderildi statusune cekilecek.
                      UPDATE ALZ_GHLTH_PORTAL_USER
                      SET    STATUS = 2
                      WHERE USER_NAME = p_created_username;
                      
                      UPDATE GHLTH_PORTAL_USER_EXTRA_LIST@OPUSDEVL 
                      SET ADMIN_EMAIL_SENT = 1
                      WHERE USER_NAME = rec_portal_user_info.USER_NAME;
                      
                      UPDATE WEB_SEC_SYSTEM_USERS 
                      SET  REFERENCE_OPUS_USER = p_created_username
                      WHERE USER_NAME          = p_created_username;
                      
                    END IF;
                ELSE
                    UPDATE ALZ_GHLTH_PORTAL_USER
                    SET    STATUS = 3
                    WHERE  USER_NAME = p_created_username;
                    
                    UPDATE WEB_SEC_SYSTEM_USERS
                    SET  USER_PASSWORD_AES = v_enc_policy_user_pass, ACTIVE = 1
                    WHERE USER_NAME        = p_created_username;  
                END IF;
                dbms_output.put_line('admin kullanicisi olusturuldu');
            END IF;
            
            -- admin olan ve olmayanlar icin kullanicisi olusturulacak.
            p_created_username := 'W' || rec_portal_user_info.USER_NAME;
            dbms_output.put_line(p_created_username);
            dbms_output.put_line('police kullanicisi olusturulacak');
            
            IF rec_portal_user_info.ph_part_id is not null or rec_portal_user_info.kullanici_yetki = 'Sigorta Ettiren' THEN
                v_rel_type := 'POLICY_HOLDER';
            ELSE
                v_rel_type := 'POLICY';
            END IF;
            
            INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER PR
                        (PR.USER_NAME,
                         PR.NAME,
                         PR.SURNAME,
                         PR.EMAIL,
                         PR.GSM,
                         PR.REL_TYPE,
                         PR.IS_ADMIN,
                         PR.STATUS,
                         PR.ACTION_CODE,
                         PR.TOKEN,
                         PR.ENC_TOKEN,
                         PR.CREATE_USER,
                         PR.CREATE_DATE
                         )
                 VALUES(p_created_username,
                        rec_portal_user_info.FIRST_NAME,
                        rec_portal_user_info.LAST_NAME,
                        rec_portal_user_info.EMAIL,
                        v_portal_user_gsm,
                        v_rel_type,
                        0,
                        1,
                        'A',
                        rec_portal_user_info.USER_TOKEN,
                        rec_portal_user_info.USER_TOKEN_ENC,
                        'GHLTH-PORTAL',
                        sysdate);
            
            IF rec_portal_user_info.ph_part_id is not null THEN
                IF rec_portal_user_info.description is not null THEN
                    dbms_output.put_line(rec_portal_user_info.description);
                    FOR rec_main_group_info IN (SELECT REGEXP_SUBSTR (rec_portal_user_info.DESCRIPTION,
                                                         '[^;]+',
                                                         1,
                                                         LEVEL) TXT FROM DUAL
                                               CONNECT BY REGEXP_SUBSTR (rec_portal_user_info.DESCRIPTION,
                                                                         '[^;]+',
                                                                         1,
                                                                         LEVEL)
                                                             IS NOT NULL)
                    LOOP
                        p_main_group_code     := trim(rec_main_group_info.txt);
                        v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                        INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                                (RD.ID,
                                 RD.USER_NAME,
                                 RD.PH_PART_ID,
                                 RD.MAIN_GROUP_CODE,
                                 RD.CREATE_DATE)
                          VALUES(v_portal_user_rel_seq,
                                 p_created_username,
                                 rec_portal_user_info.ph_part_id,
                                 p_main_group_code,
                                 SYSDATE);
                    END LOOP;
                ELSE
                    v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                    INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                            (RD.ID,
                             RD.USER_NAME,
                             RD.PH_PART_ID,
                             RD.MAIN_GROUP_CODE,
                             RD.CREATE_DATE)
                      VALUES(v_portal_user_rel_seq,
                             p_created_username,
                             rec_portal_user_info.ph_part_id,
                             p_main_group_code_info,
                             SYSDATE);
                END IF;
            ELSE
                IF rec_portal_user_info.kullanici_yetki = 'Sigorta Ettiren' THEN
                    FOR rec_policy_user_info in (SELECT DISTINCT get_policy_holder_info(b.contract_id,'PART_ID') se_unsur,
                                                                 a.main_group_code
                                                    FROM koc_ocp_pol_versions_ext b,
                                                       koc_cp_group_master a,
                                                       ocp_policy_bases c,
                                                       koc_ocp_pol_contracts_ext d,
                                                       ocp_policy_contracts cc
                                                    WHERE a.group_code = upper(rec_portal_user_info.GROUP_CODE)
                                                    AND   b.group_code = a.group_code
                                                    AND   c.contract_id = b.contract_id
                                                    AND   c.term_start_date = a.policy_start_date
                                                    AND   c.term_end_date = a.policy_end_date
                                                    AND   c.term_end_date >= TRUNC(SYSDATE-60)
                                                    AND   b.signature_date BETWEEN a.validity_start_date AND NVL(a.validity_end_date,b.signature_date)
                                                    AND   d.contract_id = c.contract_id
                                                    AND   cc.contract_id = c.contract_id
                                                    AND   NVL(cc.contract_status, 'I') <> 'O')
                    LOOP
                        v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                        INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                                (RD.ID,
                                 RD.USER_NAME,
                                 RD.PH_PART_ID,
                                 RD.MAIN_GROUP_CODE,
                                 RD.CREATE_DATE)
                          VALUES(v_portal_user_rel_seq,
                                 p_created_username,
                                 rec_policy_user_info.se_unsur,
                                 rec_policy_user_info.main_group_code,
                                 SYSDATE);
                    END LOOP;
                ELSE
                    FOR rec_policy_user_info in (SELECT DISTINCT c.policy_ref,
                                                                 c.contract_id,
                                                                 a.main_group_code
                                                    FROM koc_ocp_pol_versions_ext b,
                                                       koc_cp_group_master a,
                                                       ocp_policy_bases c,
                                                       koc_ocp_pol_contracts_ext d,
                                                       ocp_policy_contracts cc
                                                    WHERE a.group_code = upper(rec_portal_user_info.GROUP_CODE)
                                                    AND   b.group_code = a.group_code
                                                    AND   c.contract_id = b.contract_id
                                                    AND   c.term_start_date = a.policy_start_date
                                                    AND   c.term_end_date = a.policy_end_date
                                                    AND   c.term_end_date >= TRUNC(SYSDATE-60)
                                                    AND   b.signature_date BETWEEN trunc(a.validity_start_date) AND NVL(a.validity_end_date,b.signature_date)
                                                    AND   d.contract_id = c.contract_id
                                                    AND   cc.contract_id = c.contract_id
                                                    AND   NVL(cc.contract_status, 'I') <> 'O')
                    LOOP
                        v_portal_user_rel_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
                        INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                                (RD.ID,
                                 RD.USER_NAME,
                                 RD.POLICY_REF,
                                 RD.CONTRACT_ID,
                                 RD.GROUP_CODE,
                                 RD.MAIN_GROUP_CODE,
                                 RD.CREATE_DATE)
                          VALUES(v_portal_user_rel_seq,
                                 p_created_username,
                                 rec_policy_user_info.POLICY_REF,
                                 rec_policy_user_info.CONTRACT_ID,
                                 upper(rec_portal_user_info.GROUP_CODE),
                                 rec_policy_user_info.MAIN_GROUP_CODE,
                                 SYSDATE);
                    END LOOP;
                END IF;
            END IF;
            
            v_auth_role_table := Customer.char_array();
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WGSIKADMIN';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WLOGIN';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPDASHB';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPPRTL';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPUINS';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPEINS';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPOTHER';
            v_auth_role_table.extend;
            v_auth_role_table(v_auth_role_table.count) := 'WPGSPDOC';
            
            ALZ_GHLTH_POLICY_UTILS7.create_web_user_automatically (p_created_username,
                                                                   rec_portal_user_info.FIRST_NAME,
                                                                   rec_portal_user_info.LAST_NAME,
                                                                   null,  -- password sonra set edilecek. sifre belirleme adiminda kullanici belirleyecek.
                                                                   rec_portal_user_info.EMAIL,
                                                                   NULL,
                                                                   'SYSTEM-GHLTH-PORTAL',
                                                                   v_auth_role_table,
                                                                   p_process_results);
                                             
              UPDATE WEB_SEC_SYSTEM_USERS 
              SET  USER_PASSWORD_AES = v_enc_policy_user_pass,
                   REFERENCE_OPUS_USER = p_created_username
              WHERE USER_NAME        = p_created_username;
              
              IF rec_portal_user_info.USER_EMAIL_SENT = 0 THEN
                    -- sifre belirleme linki gonderilecek.                               
                    v_mail_content := policy_user_link_mail_body;
                    v_mail_content := replace(v_mail_content, '%%name%%',     rec_portal_user_info.FIRST_NAME);
                    v_mail_content := replace(v_mail_content, '%%surname%%',  rec_portal_user_info.LAST_NAME);
                    v_mail_content := replace(v_mail_content, '%%UW_COMPANY_REP_USER_LINK%%', v_mail_policy_user_link);
                    v_mail_content := replace(v_mail_content, '%%token%%',    rec_portal_user_info.USER_TOKEN_ENC);
                    v_mail_content := replace(v_mail_content, '%%username%%', p_created_username);

                    p_mail := '<p><span style=font-family: arial, helvetica, sans-serif; font-size: x-small;>'|| v_mail_content ||'</span></p>';

                    v_String_Rec_to.delete();
                    v_String_Rec_to.extend;
                    IF v_service_name = 'OPUSDATA' THEN
                        v_String_Rec_to(1) := String_Rec(rec_portal_user_info.EMAIL);
                    ELSE
                        v_String_Rec_to(1) := String_Rec('extern.mehmetsami-alpak@allianz.com.tr');    
                    END IF;
                        
                    v_Mail_Input := customer.EuroMsg_Mail_Input_Rec (null,
                                                                     'Template',
                                                                     null,
                                                                     v_String_Rec_to,
                                                                     null,
                                                                     null,
                                                                     policy_user_link_mail_subject,
                                                                     p_mail,
                                                                     'GROUP_PORTAL_MAIL',
                                                                     null, --v_Report_Parameters,
                                                                     '045',
                                                                     rec_portal_user_info.USER_NAME,
                                                                     null);
                    Alz_euromsg_utils.Send_Mail(v_Mail_Input,
                                                'GROUP_PORTAL_MAIL',
                                                p_Response_Rec,
                                                p_Process_Results);

                    v_Email_Sent := 0;

                    FOR i IN 1 .. p_Response_Rec.COUNT
                    LOOP
                         If  v_Email_Sent = 0
                             and p_Response_Rec(i).Hata_Code = '200'
                             and lower(p_Response_Rec(i).Response_Name) = 'code'
                             and p_Response_Rec(i).Response_Value = '0' then
                         --Mail Gönderimi baþarýlý
                         v_Email_Sent := 1;
                     End if;
                    END LOOP;
                    
                    IF v_Email_Sent = 1 THEN
                       -- sifresi olanlar icin link maili gonderildi statusune cekilecek. 
                       -- zaten cogu oyle. sadece 3 tane olmayan var.
                       IF v_enc_policy_user_pass is not null THEN
                           UPDATE ALZ_GHLTH_PORTAL_USER
                           SET    STATUS = 3
                           WHERE USER_NAME = p_created_username;
                       ELSE
                           UPDATE ALZ_GHLTH_PORTAL_USER
                           SET    STATUS = 2
                           WHERE USER_NAME = p_created_username;
                       END IF;
                       
                       UPDATE GHLTH_PORTAL_USER_EXTRA_LIST@OPUSDEVL
                       SET USER_EMAIL_SENT = 1
                       WHERE USER_NAME = rec_portal_user_info.USER_NAME;
                    END IF;
              ELSE
                 UPDATE ALZ_GHLTH_PORTAL_USER
                 SET    STATUS = 3
                 WHERE USER_NAME = p_created_username;
                 
                 UPDATE WEB_SEC_SYSTEM_USERS SET ACTIVE = 1 WHERE USER_NAME = p_created_username;
              END IF;
              
              p_main_group_code := null;  
              dbms_output.put_line('police kullanicisi olusturuldu.');
        ELSE
            dbms_output.put_line('ust grubu olmayan kullanici :'|| rec_portal_user_info.USER_NAME);
        END IF;
        --END IF;
        commit;
    END LOOP;
    
    DBMS_OUTPUT.put_line('finishing time : '|| TO_CHAR (SYSDATE,'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.put_line('starting time of rec_5001_info : '|| TO_CHAR (SYSDATE,'YYYY-MM-DD HH24:MI:SS'));
    for rec_5001_info in(select * from alz_ghlth_portal_user_rel 
                         where ph_part_id is not null
                         and main_group_code = 'S5001')
    loop
        v_count_11159 := 0;
        
        select count(*) into v_count_11159
        from ocp_interested_parties p, 
             ocp_ip_links pl, 
             ocp_policy_bases pb,
             koc_ocp_pol_versions_ext b,
             koc_cp_group_master a
        where p.ip_no = pl.ip_no
        AND   p.VERSION_NO    = pl.VERSION_NO
        and   p.top_indicator = 'Y'
        and   pl.top_indicator = 'Y'
        and   p.action_code <> 'D'
        and   pl.action_code <> 'D' 
        and   pl.contract_id = pb.contract_id
        and   PB.CONTRACT_ID = p.contract_id
        and   p.partner_id = rec_5001_info.PH_PART_ID
        and   pl.role_type = 'PH'
        AND   pb.term_end_date >= TRUNC(SYSDATE-60)
        and   pb.top_indicator = 'Y'
        AND   a.group_code = b.group_code
        and   a.validity_start_date = (select max(validity_start_date)
		                               from koc_cp_group_master ma 
									   where ma.group_code = a.group_code 
									   and ma.policy_start_date = a.policy_start_date)
        AND pb.contract_id = b.contract_id
        AND pb.term_start_date = a.policy_start_date
        AND pb.term_end_date = a.policy_end_date
        AND exists (SELECT 1 FROM OCP_POLICY_VERSIONS pv 
                           WHERE  pv.contract_id = pb.contract_id 
                           AND    pv.top_indicator = 'Y' 
                           AND    pv.product_id = 64)
        and a.main_group_code = 'S11159';
        
        IF v_count_11159 > 0 THEN
            v_rel_log_id_seq := CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL_SEQ.NEXTVAL;
            
            INSERT INTO CUSTOMER.ALZ_GHLTH_PORTAL_USER_REL RD
                    (RD.ID,
                     RD.USER_NAME,
                     RD.PH_PART_ID,
                     RD.MAIN_GROUP_CODE,
                     RD.CREATE_DATE)
              VALUES(v_rel_log_id_seq,
                     rec_5001_info.USER_NAME,
                     rec_5001_info.PH_PART_ID,
                     'S11159',
                     SYSDATE);
               commit;
        END IF;
    end loop;
    DBMS_OUTPUT.put_line('finishing time of rec_5001_info : '|| TO_CHAR (SYSDATE,'YYYY-MM-DD HH24:MI:SS'));
	update alz_ghlth_portal_user 
	set email = 'eapaydin@boynergrup.com', name = 'EMÝNE', surname = 'APAYDIN' 
	where user_name in ('WGRYTKA1688', 'WAGRYTKA1688');
	
	update alz_ghlth_portal_user 
	set email = 'kubra.turyan@accenture.com', name = 'KÜBRA', surname = 'TURYAN'
	where user_name in ('WGRYTAZ498501', 'WAGRYTAZ498501');
	commit;
end;
/
