create or replace
procedure tcel_envia_email_fornecedor_tie (
			nr_ordem_compra_p	number,
			cd_estabelecimento_p	number,
			cd_fornecedor_p			varchar2,
			nm_usuario_p		varchar2) is

recipient_w				pessoa_juridica.ds_email%type;
JSON_W PHILIPS_JSON := PHILIPS_JSON(); 
JSON_DATA_W              CLOB;
json_array_w philips_json_list := philips_json_list();
json_parameters_w philips_json := philips_json();

begin

	select	substr(nvl(b.ds_email,a.ds_email),1,2000)
	into	recipient_w
	from	pessoa_juridica_estab b,
		pessoa_juridica a
	where	a.cd_cgc = b.cd_cgc(+)
	and	nvl(b.cd_estabelecimento, cd_estabelecimento_p) = cd_estabelecimento_p
	and	a.cd_cgc = cd_fornecedor_p;
	
	if (recipient_w is not null) then

		JSON_W.PUT('code', 510);
		JSON_W.PUT('type', 'CSUP');
		JSON_W.PUT('title', 'Ordem_Compra ' || nr_ordem_compra_p);
		JSON_W.PUT('subject', 'Ordem Compra ' || nr_ordem_compra_p);
		JSON_W.PUT('content', 'Dados referentes a Ordem Compra ' || nr_ordem_compra_p);		
		
        json_parameters_w.put('NR_ORDEM_COMPRA', nr_ordem_compra_p);      
        JSON_W.PUT('parameters', json_parameters_w);
        
        json_array_w.append(recipient_w);
        JSON_W.put('recipientEmails', json_array_w);
        
        JSON_W.PUT('readCOnfirmation', 'true');

		SYS.DBMS_LOB.CREATETEMPORARY(JSON_DATA_W, TRUE); 
		JSON_W.TO_CLOB(JSON_DATA_W); 
		
        JSON_DATA_W := BIFROST.SEND_INTEGRATION_CONTENT('opme.export.purchase.order.event', JSON_DATA_W, nm_usuario_p); 

	end if;

end tcel_envia_email_fornecedor_tie;
/
