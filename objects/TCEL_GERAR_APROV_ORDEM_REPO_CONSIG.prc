create or replace
procedure tcel_gerar_aprov_ordem_repo_consig(
			cd_estabelecimento_p	number,
			cd_fornecedor_consignado_p	varchar2,
			cd_local_entrega_p	number,
			nr_atendimento_p	number,
			nr_prescricao_p	number,
			cd_material_p	number,
			cd_local_estoque_p	number,
			nm_usuario_p	varchar2,
			ie_tipo_ordem_p varchar2) is

nr_ordem_compra_w			number(10);
cd_operacao_estoque_w		number(4,0);
cd_grupo_material_w			number(03,0);
cd_subgrupo_w				number(03,0);
cd_classe_material_w		number(05,0);
cd_convenio_w				number(05,0);
cd_setor_prescricao_w		number(10);
ie_gera_oc_reposicao_w		varchar2(1);
ie_aprovar_oc_reposicao_w	varchar2(1);
qt_existe_w					number(10);

cursor	c01 is
	select	nvl(a.ie_gera_oc_reposicao,'N'),
		nvl(b.ie_aprovar_oc_reposicao,'N')
	from	regra_ordem_consignado a,
		tcel_regorco b
	where	a.cd_estabelecimento = cd_estabelecimento_p
	and	a.cd_local_estoque = cd_local_estoque_p
	and	a.cd_operacao_estoque = cd_operacao_estoque_w
	and	nvl(a.cd_grupo_material, cd_grupo_material_w) = cd_grupo_material_w
	and	nvl(a.cd_subgrupo_material, cd_subgrupo_w) = cd_subgrupo_w
	and	nvl(a.cd_classe_material, cd_classe_material_w) = cd_classe_material_w
	and	nvl(a.cd_material, cd_material_p) = cd_material_p
	and	nvl(a.cd_fornecedor, cd_fornecedor_consignado_p) = cd_fornecedor_consignado_p
	and	nvl(a.cd_convenio, cd_convenio_w) = cd_convenio_w
	and	nvl(a.cd_setor_prescricao, cd_setor_prescricao_w) = cd_setor_prescricao_w
	and a.nr_sequencia = b.nr_sequencia
	order by
		nvl(a.cd_fornecedor, '0'),
		nvl(a.cd_convenio, 0),
		nvl(a.cd_setor_prescricao, 0),
		nvl(a.cd_material, 0),
		nvl(a.cd_classe_material, 0),
		nvl(a.cd_subgrupo_material, 0),
		nvl(a.cd_grupo_material, 0);

begin

nr_ordem_compra_w := 0;

if (ie_tipo_ordem_p = 'W') then

	select	nvl(obter_ordem_atend_consignado(cd_estabelecimento_p, cd_fornecedor_consignado_p, cd_local_entrega_p, 0, nr_atendimento_p, nr_prescricao_p,'W'),0)
	into	nr_ordem_compra_w
	from	dual;

end if;

if	(nr_ordem_compra_w > 0) then

	select	nvl(cd_operacao_cons_consignado, cd_operacao_cons_paciente)
	into	cd_operacao_estoque_w
	from	parametro_estoque
	where	cd_estabelecimento = cd_estabelecimento_p;
	
	if	(cd_operacao_estoque_w > 0) then
	
		select	cd_grupo_material,
		cd_subgrupo_material,
		cd_classe_material
		into	cd_grupo_material_w,
		cd_subgrupo_w,
		cd_classe_material_w
		from	estrutura_material_v
		where 	cd_material = cd_material_p;
	
		cd_convenio_w := nvl(obter_convenio_atendimento(nr_atendimento_p),0);
	
		select cd_setor_orig
		into cd_setor_prescricao_w
		from prescr_medica
		where nr_prescricao = nr_prescricao_p;
	
		begin
			open	c01;
			loop
			fetch	c01 into 
				ie_gera_oc_reposicao_w,
				ie_aprovar_oc_reposicao_w;
			exit when c01%notfound;
			end loop;
			close 	c01;
		end;
	
		if	((ie_gera_oc_reposicao_w = 'S') and ((ie_aprovar_oc_reposicao_w = 'S') or ie_aprovar_oc_reposicao_w = 'E')) then
			select	count(*)
			into	qt_existe_w
			from	ordem_compra
			where	nr_ordem_compra	= nr_ordem_compra_w
			and	dt_aprovacao is null;
			/*Para verificar se a OC ja nao esta aprovada ou reprovada*/
			if	(qt_existe_w > 0) then
				tcel_gerar_aprov_ordem_compra(nr_ordem_compra_w, null, nm_usuario_p);
				
				if (ie_aprovar_oc_reposicao_w = 'E') then
				tcel_envia_email_fornecedor_tie(nr_ordem_compra_w,cd_estabelecimento_p, cd_fornecedor_consignado_p, nm_usuario_p);
				/*Chamar TIE*/
				end if;
			end if;
		end if;
	end if;
end if;
			
end tcel_gerar_aprov_ordem_repo_consig;
/
