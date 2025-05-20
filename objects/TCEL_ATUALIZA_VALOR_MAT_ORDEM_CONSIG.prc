create or replace procedure tcel_atualiza_valor_mat_ordem_consig(
			cd_estabelecimento_p in number,
			cd_fornecedor_consignado_p in varchar2,
			cd_local_entrega_p in number,
			nr_atendimento_p in number,
			nr_prescricao_p in number,
			cd_material_p in number,
			qt_compra_p in number,
			nm_usuario_p in varchar2,
			nr_seq_lote_fornec_p in number,
			ie_tipo_ordem_p in varchar2) is

nr_ordem_compra_w			number(10);
cd_convenio_w				number(05,0); 
cd_categoria_w				varchar2(10);
vl_unitario_material_w		ordem_compra_item.vl_unitario_material%type	:= 0;
vl_unitario_material2_w		ordem_compra_item.vl_unitario_material%type	:= 0;
nr_item_oci_w				ordem_compra_item.nr_item_oci%type;
cd_pessoa_fisica_fornec_w 	nota_fiscal.cd_pessoa_fisica%type;
nr_sequencia_nf_w			material_lote_fornec.nr_sequencia_nf%type;
ie_tipo_atendimento_w		number(2);
ie_preco_sus_oc_w			varchar2(1);
nr_seq_agenda_w				agenda_paciente.nr_sequencia%type;
nr_cirurgia_w				number(10,0);

begin

select	nvl(obter_ordem_atend_consignado(cd_estabelecimento_p, cd_fornecedor_consignado_p, cd_local_entrega_p, 0, nr_atendimento_p, nr_prescricao_p,ie_tipo_ordem_p),0)
into	nr_ordem_compra_w
from	dual;

if	(nr_ordem_compra_w > 0) then

	select nvl(max(nr_item_oci),0)
	into nr_item_oci_w
    from ordem_compra_item
	where nr_ordem_compra = nr_ordem_compra_w
	and cd_material = cd_material_p;
	
	select nvl(vl_unitario_material,0)
	into vl_unitario_material_w
	from ordem_compra_item
	where nr_ordem_compra = nr_ordem_compra_w
	and cd_material = cd_material_p
	and nr_item_oci = nr_item_oci_w;
			
	select	cd_convenio,
		cd_categoria
	into	cd_convenio_w,
		cd_categoria_w
	from	atendimento_paciente_v
	where	nr_atendimento	= nr_atendimento_p;
	
	select  max(matlf.nr_sequencia_nf)
    into    nr_sequencia_nf_w
    from    material_lote_fornec    matlf
    where   matlf.nr_sequencia  =   nr_seq_lote_fornec_p;

    select	max(nf.cd_pessoa_fisica)
    into	cd_pessoa_fisica_fornec_w
    from    nota_fiscal            nf
    where   nf.nr_sequencia    =   nr_sequencia_nf_w;
	
	select	nvl(ie_preco_sus_oc,'N')
	into	ie_preco_sus_oc_w
	from  	parametro_compras
	where 	cd_estabelecimento = cd_estabelecimento_p;

	if	(ie_preco_sus_oc_w = 'S') and
		(nr_atendimento_p > 0) then

		select	Obter_Dados_Atendimento(nr_atendimento_p, 'TC')
		into	ie_tipo_atendimento_w
		from	dual;
	end if;
	
	select		max(a.nr_cirurgia)
	into		nr_cirurgia_w
	from		prescr_medica a
	where 		a.nr_prescricao = nr_prescricao_p
    group by	a.nr_prescricao;
	
	select	nvl(max(a.nr_sequencia),0)
	into	nr_seq_agenda_w
	from	agenda_paciente a,
		cirurgia b
	where	a.nr_cirurgia	= b.nr_cirurgia
	and		b.nr_prescricao	= nr_prescricao_p;

	if	(nr_seq_agenda_w = 0) then
		select	nvl(max(a.nr_sequencia),0)
		into	nr_seq_agenda_w
		from	agenda_paciente a,
			cirurgia b
		where 	a.nr_cirurgia	= b.nr_cirurgia
		and		b.nr_cirurgia = nr_cirurgia_w;
	end if;
	
	tcel_obter_vl_mat_ordem_consig(
		cd_estabelecimento_p        =>  cd_estabelecimento_p,
		cd_fornecedor_consignado_p  =>  cd_fornecedor_consignado_p,
		cd_pessoa_fisica_fornec_p   =>  cd_pessoa_fisica_fornec_w,
		cd_material_p               =>  cd_material_p,
		nr_ordem_compra_p           =>  nr_ordem_compra_w,
		nr_prescricao_p             =>  nr_prescricao_p,
		nr_atendimento_p            =>  nr_atendimento_p,
		ie_tipo_atendimento_p       =>  ie_tipo_atendimento_w,
		nr_seq_agenda_p             =>  nr_seq_agenda_w,
		dt_atualizacao_p            =>  sysdate,
		nr_seq_lote_fornec_p        =>  nr_seq_lote_fornec_p,
		cd_convenio_p               =>  cd_convenio_w,
		cd_categoria_p              =>  cd_categoria_w,
		dt_vigencia_p               =>  sysdate,
		vl_unitario_material_p      =>  vl_unitario_material2_w
	);
		
	if	(nvl(vl_unitario_material2_w,0) > 0) and (nvl(vl_unitario_material_w,0) != nvl(vl_unitario_material2_w,0)) then
	
		update	ordem_compra_item
		set	vl_unitario_material = vl_unitario_material2_w,
			nm_usuario = nm_usuario_p,
			dt_atualizacao = sysdate,
			vl_total_item = round((qt_compra_p * vl_unitario_material2_w),4)
		where	nr_ordem_compra = nr_ordem_compra_w
		and cd_material = cd_material_p
		and nr_item_oci = nr_item_oci_w;
			
		Calcular_Liquido_Ordem_Compra(nr_ordem_compra_w, nm_usuario_p);
		gerar_ordem_compra_venc(nr_ordem_compra_w, nm_usuario_p);
		
		commit;
	end if;
end if;

end tcel_atualiza_valor_mat_ordem_consig;
/
