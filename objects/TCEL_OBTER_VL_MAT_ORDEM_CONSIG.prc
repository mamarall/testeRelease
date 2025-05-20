create or replace
procedure tcel_obter_vl_mat_ordem_consig(
    cd_estabelecimento_p        in  material_lote_fornec.cd_estabelecimento%type,
    cd_fornecedor_consignado_p	in  nota_fiscal.cd_cgc_emitente%type,
    cd_pessoa_fisica_fornec_p   in  nota_fiscal.cd_pessoa_fisica%type default null,
    cd_material_p               in  material.cd_material%type,
    nr_ordem_compra_p           in  ordem_compra.nr_ordem_compra%type,
    nr_prescricao_p             in  material_atend_paciente.nr_prescricao%type,
    nr_atendimento_p            in  material_atend_paciente.nr_atendimento%type,
    ie_tipo_atendimento_p       in  regra_valor_ordem_consig.ie_valor_consignado%type,
    nr_seq_agenda_p             in  agenda_paciente.nr_sequencia%type,
    dt_atualizacao_p            in  nota_fiscal.dt_atualizacao%type,
    nr_seq_lote_fornec_p        in  material_lote_fornec.nr_sequencia%type,
    cd_convenio_p               in  material_atend_paciente.cd_convenio%type,
    cd_categoria_p              in  atendimento_paciente_v.cd_categoria%type,
    dt_vigencia_p               in  nota_fiscal_item.dt_validade%type,
    vl_unitario_material_p      out nota_fiscal_item.vl_unitario_item_nf%type
) is


nr_sequencia_w				regra_valor_ordem_consig.nr_sequencia%type;
cd_grupo_material_w			grupo_material.cd_grupo_material%type;
cd_subgrupo_material_w			subgrupo_material.cd_subgrupo_material%type;
cd_classe_material_w			classe_material.cd_classe_material%type;
ie_valor_consignado_w			regra_preco_ordem_consig.ie_valor_consignado%type := 'N';
vl_unitario_material_w			ordem_compra_item.vl_unitario_material%type	:= 0;
vl_preco_tabela_w			preco_material.vl_preco_venda%type;
qt_conv_compra_estoque_w		material.qt_conv_compra_estoque%type;
qt_conv_estoque_consumo_w		material.qt_conv_estoque_consumo%type;
cd_tab_preco_mat_consig_w		parametro_compras.cd_tab_preco_mat_consig%type;
dt_utl_vigencia_w			date;
cd_tab_preco_mat_w			number(10,0);
ie_origem_preco_w			number(10,0);
nr_seq_bras_preco_w			number(10,0);
nr_seq_mat_bras_w			number(10,0);
nr_seq_conv_bras_w			number(10,0);
nr_seq_conv_simpro_w			number(10,0);
nr_seq_mat_simpro_w			number(10,0);
nr_seq_simpro_preco_w			number(10,0);
nr_seq_ajuste_mat_w			number(10,0);
nr_seq_marca_w				marca.nr_sequencia%type;
nr_cirurgia_w				cirurgia.nr_cirurgia%type;
nr_seq_agenda_w				agenda_paciente.nr_sequencia%type;
cd_convenio_w				convenio.cd_convenio%type;
ie_preco_sus_oc_w			varchar2(1);
cd_procedimento_w			number(15);
nr_proc_interno_w procedimento.nr_proc_interno%type;

cursor c01 is
select	nr_sequencia
from	regra_valor_ordem_consig
where	cd_estabelecimento = cd_estabelecimento_p
and	nvl(cd_grupo_material, cd_grupo_material_w)		= cd_grupo_material_w
and	nvl(cd_subgrupo_material, cd_subgrupo_material_w)	= cd_subgrupo_material_w
and	nvl(cd_classe_material, cd_classe_material_w)		= cd_classe_material_w
and	(nvl(cd_material, cd_material_p) 			= cd_material_p or cd_material_p = 0)
and	((nvl(cd_cnpj, cd_fornecedor_consignado_p)		= cd_fornecedor_consignado_p) or (cd_cnpj is null))
order by
	nvl(cd_material, 0),
	nvl(cd_classe_material, 0),
	nvl(cd_subgrupo_material, 0),
	nvl(cd_grupo_material, 0),
	nvl(cd_cnpj, 'xxx');

cursor c02 is
select	ie_valor_consignado
from	regra_preco_ordem_consig
where	nr_seq_regra = nr_sequencia_w
order by nr_seq_prioridade;

begin

nr_seq_agenda_w := nvl(nr_seq_agenda_p,0);
cd_convenio_w	:= cd_convenio_p;

select	a.cd_grupo_material,
	a.cd_subgrupo_material,
	a.cd_classe_material
into	cd_grupo_material_w,
	cd_subgrupo_material_w,
	cd_classe_material_w
from	estrutura_material_v a
where	a.cd_material = cd_material_p;

select	qt_conv_compra_estoque,
	qt_conv_estoque_consumo
into 	qt_conv_compra_estoque_w,
	qt_conv_estoque_consumo_w
from 	material
where 	cd_material = nvl(cd_material_p,0);

select	cd_tab_preco_mat_consig
into	cd_tab_preco_mat_consig_w
from	parametro_compras
where	cd_estabelecimento = cd_estabelecimento_p;

open C01;
loop
fetch C01 into
	nr_sequencia_w;
exit when C01%notfound;
	begin
	/*Busca a sequencia da regra de preco de acordo com as informacoes do material*/
	nr_sequencia_w := nr_sequencia_w;
	end;
end loop;
close C01;

if	(nr_sequencia_w > 0) then

	/*Esse cursor serve para bucar o preco conforme a regra, seguindo a prioridade.
	Quando ele encontra o valor, ele sai fora do cursor. Enquanto o valor e zero, ele vai tentando buscar o preco*/
	open C02;
	loop
	fetch C02 into
		ie_valor_consignado_w;
	exit when C02%notfound or vl_unitario_material_w > 0;
		begin
		
		/*Tabela de Oportunidades*/
		
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'V') then
			
			select	nvl(max(nr_cirurgia),0)
			into	nr_cirurgia_w
			from	ordem_compra
			where	nr_ordem_compra = nr_ordem_compra_p;

			if	(nr_cirurgia_w > 0) then
			
				select	nvl(max(cd_procedimento_princ),0)
				into	cd_procedimento_w
				from	cirurgia a
				where	a.nr_cirurgia		= nr_cirurgia_w;
				
				if	(cd_procedimento_w > 0) then
				
					select nvl(max(nr_sequencia),0)
					into   nr_proc_interno_w
					from   proc_interno
					where  cd_procedimento = cd_procedimento_w;
					
					if	(nr_proc_interno_w > 0) then
			
						select nvl(max(b.vl_unitario_item), 0)
						into vl_unitario_material_w
						from tcel_regra_preco_consig_item a,
							tcel_regra_preco_item_valor b
						where a.cd_estabelecimento = cd_estabelecimento_p
						and a.cd_procedimento = nr_proc_interno_w
						and a.cd_fornecedor = cd_fornecedor_consignado_p
						and a.cd_convenio = cd_convenio_p
						and (a.cd_categoria = cd_categoria_p or nvl(a.cd_categoria,0) = 0 or nvl(cd_categoria_p,0) = 0)
						and a.ie_situacao = 'A'
						and a.nr_sequencia = b.nr_seq_regra
						and b.cd_material = cd_material_p;

					end if;
				end if;
			end if;		
		end if;

		/*Tabela de precos*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'T') then

			select	nvl(max(a.vl_preco_venda),0)
			into	vl_preco_tabela_w
			from	preco_material a
			where	a.cd_material		= cd_material_p
			and	a.cd_estabelecimento	= cd_estabelecimento_p
			and	a.cd_cgc_fornecedor	= cd_fornecedor_consignado_p
			and	a.cd_tab_preco_mat	= nvl(cd_tab_preco_mat_consig_w,a.cd_tab_preco_mat)
			and	a.ie_situacao		= 'A'
			and	a.dt_inicio_vigencia	= (
				select	max(b.dt_inicio_vigencia)
				from	preco_material b
				where	b.cd_material		= a.cd_material
				and	b.cd_cgc_fornecedor	= a.cd_cgc_fornecedor
				and	b.cd_estabelecimento	= a.cd_estabelecimento
				and	b.ie_situacao		= 'A'
				and	b.cd_tab_preco_mat	= nvl(cd_tab_preco_mat_consig_w,a.cd_tab_preco_mat));

			if	(vl_preco_tabela_w <> 0) then
				vl_unitario_material_w 	:= vl_preco_tabela_w;
			end if;

			vl_unitario_material_w	:= (vl_unitario_material_w * qt_conv_compra_estoque_w * qt_conv_estoque_consumo_w);
		end if;

		/*Preco convenio*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'P') then

			if	(nvl(nr_seq_lote_fornec_p,0) <> 0) then
				select	max(nr_seq_marca)
				into	nr_seq_marca_w
				from	material_lote_fornec
				where	nr_sequencia = nr_seq_lote_fornec_p;
			end if;

			define_preco_material(	cd_estabelecimento_p,	-- cd_estabelecimento_p		number,
						cd_convenio_w,          -- cd_convenio_p          	number,
						cd_categoria_p,         -- cd_categoria_p         	varchar2,
						dt_vigencia_p,          -- dt_vigencia_p          	date,
						cd_material_p,          -- cd_material_p          	number,
						0,                      -- cd_tipo_acomodacao_p   	number,
						0,                      -- ie_tipo_atendimento_p  	number,
						0,                      -- cd_setor_atendimento_p 	number,
						null,                   -- cd_cgc_fornecedor_p		varchar2,
						0,                      -- qt_idade_p			number,
						0,                      -- nr_sequencia_p		number,
						null,                   -- cd_plano_p			varchar2,
						null,                   -- cd_proc_referencia_p		number,
						null,                   -- ie_origem_proc_p		number,
						nr_seq_marca_w,         -- nr_seq_marca_p		number,
						null,                   -- ie_clinica_p			number,
						null,                   -- nr_seq_classif_atend_p	number,
						nr_atendimento_p,       -- nr_atendimento_p		number,
						null,                   -- ie_vago_4_p			varchar2,
						vl_unitario_material_w, -- vl_material_p      	 out 	number,
						dt_utl_vigencia_w,      -- dt_ult_vigencia_p  	 out 	date,
						cd_tab_preco_mat_w,     -- cd_tab_preco_mat_p 	 out 	number,
						ie_origem_preco_w,      -- ie_origem_preco_p  	 out 	number,
						nr_seq_bras_preco_w,    -- nr_seq_bras_preco_p	 out	number,
						nr_seq_mat_bras_w,      -- nr_seq_mat_bras_p	 out	number,
						nr_seq_conv_bras_w,     -- nr_seq_conv_bras_p	 out	number,
						nr_seq_conv_simpro_w,   -- nr_seq_conv_simpro_p	 out	number,
						nr_seq_mat_simpro_w,    -- nr_seq_mat_simpro_p	 out	number,
						nr_seq_simpro_preco_w,  -- nr_seq_simpro_preco_p out	number,
						nr_seq_ajuste_mat_w);   -- nr_seq_ajuste_mat_p	 out	number

			vl_unitario_material_w	:= (vl_unitario_material_w * qt_conv_compra_estoque_w * qt_conv_estoque_consumo_w);
		end if;


		/*Autorizacao (Valor do fornecedor)*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'F') then

			if	(nvl(nr_seq_agenda_w,0) = 0) then

				select	nvl(max(nr_cirurgia),0)
				into	nr_cirurgia_w
				from	ordem_compra
				where	nr_ordem_compra = nr_ordem_compra_p;

				if	(nr_cirurgia_w > 0) then
					select	nvl(max(a.nr_sequencia),0)
					into	nr_seq_agenda_w
					from	agenda_paciente a,
						cirurgia b
					where	a.nr_cirurgia	= b.nr_cirurgia
					and	b.nr_cirurgia	= nr_cirurgia_w;
				end if;
			end if;

			select	nvl(max(c.vl_unitario_cotado),0)
			into	vl_unitario_material_w
			from	material_autor_cirurgia b,
				autorizacao_cirurgia a,
				material_autor_cir_cot c
			where	a.nr_sequencia	= b.nr_seq_autorizacao
			and	b.cd_material	= cd_material_p
			and	a.nr_seq_agenda	= nr_seq_agenda_w
			and 	b.nr_sequencia 	= c.nr_sequencia
			and 	c.cd_cgc	= cd_fornecedor_consignado_p
			and	((nvl(a.nr_prescricao,0) = nvl(nr_prescricao_p,0)) or (nvl(nr_prescricao_p,0) = 0));
		end if;


		/*Autorizacao (Valor autorizado)*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'A') then

			if	(nvl(nr_seq_agenda_w,0) = 0) then

				select	nvl(max(nr_cirurgia),0)
				into	nr_cirurgia_w
				from	ordem_compra
				where	nr_ordem_compra = nr_ordem_compra_p;

				if	(nr_cirurgia_w > 0) then
					select	nvl(max(a.nr_sequencia),0)
					into	nr_seq_agenda_w
					from	agenda_paciente a,
						cirurgia b
					where	a.nr_cirurgia	= b.nr_cirurgia
					and	b.nr_cirurgia	= nr_cirurgia_w;
				end if;
			end if;


			select	nvl(max(b.vl_unitario_material),0)
			into	vl_unitario_material_w
			from	material_autor_cirurgia b,
				autorizacao_cirurgia a
			where	a.nr_sequencia	= b.nr_seq_autorizacao
			and	b.cd_material	= cd_material_p
			and	a.nr_seq_agenda	= nr_seq_agenda_w
			and	b.ie_valor_informado = 'S';
		end if;


		/*Ultima compra*/
		if	(nvl(vl_unitario_material_w, 0) = 0) and (ie_valor_consignado_w	= 'U') then
	                select	nvl(max(dividir((a.vl_total_item_nf - a.vl_desconto - vl_desconto_rateio + vl_frete + a.vl_despesa_acessoria + a.vl_seguro), a.qt_item_estoque)), 0)
	                into	vl_unitario_material_w
	                from 	nota_fiscal_item a
	                where 	a.cd_material  = cd_material_p
	                and 	a.nr_sequencia =
				(
		                        select  max(i.nr_sequencia)
		                        from	nota_fiscal_item    i,
		                                nota_fiscal         n,
		                                operacao_nota       p
		                        where	i.nr_sequencia      =   n.nr_sequencia
		                        and     i.cd_material       =   cd_material_p
		                        and     nvl(p.ie_ultima_compra, 'S') = 'S'
		                        and	p.cd_operacao_nf    =   n.cd_operacao_nf
		                        and	n.ie_situacao       =   '1'
		                        and	(
		                                    (
                                                	n.ie_tipo_nota = 'EF'
		                                        and n.cd_pessoa_fisica = cd_pessoa_fisica_fornec_p
		                                        and n.cd_cgc_emitente is null
                                            	    )
		                                    or (n.cd_cgc = cd_fornecedor_consignado_p)
		                                )
	                	);
	
	                vl_unitario_material_w	:= (vl_unitario_material_w * qt_conv_compra_estoque_w);
		end if;


		/*OPM com o procedimento SUS*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'O') then

			select	nvl(sus_obter_preco_proced(cd_estabelecimento_p, sysdate, 1, obter_proced_mat_esp_sus(cd_material_p), 7, 1),0)
			into	vl_unitario_material_w
			from	dual;
		end if;

		/*Autorizacao de materiais especiais*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w = 'E') then

			if	(cd_convenio_w is null) then
				cd_convenio_w := obter_convenio_atendimento(nr_atendimento_p);
			end if;
			obter_preco_conv_mat_fornec(cd_convenio_w, cd_fornecedor_consignado_p, cd_material_p, dt_atualizacao_p, vl_unitario_material_w);
		end if;

		/*Autorizacao sem prescricao (Valor do fornecedor)*/
		if	(nvl(vl_unitario_material_w,0) = 0) and
			(ie_valor_consignado_w	= 'D') then
			if	(nvl(nr_seq_agenda_w,0) = 0) then

				select	nvl(max(nr_cirurgia),0)
				into	nr_cirurgia_w
				from	ordem_compra
				where	nr_ordem_compra = nr_ordem_compra_p;

				if	(nr_cirurgia_w > 0) then
					select	nvl(max(a.nr_sequencia),0)
					into	nr_seq_agenda_w
					from	agenda_paciente a,
						cirurgia b
					where	a.nr_cirurgia	= b.nr_cirurgia
					and	b.nr_cirurgia	= nr_cirurgia_w;
				end if;
			end if;

			select	nvl(max(c.vl_unitario_cotado),0)
			into	vl_unitario_material_w
			from	material_autor_cirurgia b,
				autorizacao_cirurgia a,
				material_autor_cir_cot c
			where	a.nr_sequencia	= b.nr_seq_autorizacao
			and	b.cd_material	= cd_material_p
			and	a.nr_seq_agenda	= nr_seq_agenda_w
			and 	b.nr_sequencia 	= c.nr_sequencia
			and 	c.cd_cgc	= cd_fornecedor_consignado_p;
		end if;
        
        /* Contrato */
        if (nvl(pkg_i18n.get_user_locale, 'pt_BR') = 'es_MX') and(nvl(vl_unitario_material_w, 0) = 0) and
            (ie_valor_consignado_w = 'C') and (cd_pessoa_fisica_fornec_p is not null) then
            begin
               select    nvl(c.vl_saldo_total, c.vl_pagto)
               into      vl_unitario_material_w
               from      contrato            a,
                         contrato_regra_nf   c
               where     a.nr_sequencia = c.nr_seq_contrato
               and       a.cd_pessoa_contratada = cd_pessoa_fisica_fornec_p
               and       c.cd_material = cd_material_p
               and       nvl(c.dt_inicio_vigencia, sysdate) <= sysdate
               and       nvl(c.dt_fim_vigencia, sysdate) >= sysdate
               and       nvl(c.ie_situacao, 'A') = 'A'
               and       (c.cd_estab_regra = cd_estabelecimento_p or c.cd_estab_regra is null)
               and       a.dt_inicio <= sysdate
               and       nvl(dt_fim, sysdate) >= sysdate
               and       a.ie_situacao = 'A'
               and       (a.cd_estabelecimento = cd_estabelecimento_p
                            or exists (select 1 from contrato_estab_adic b
                                       where  a.nr_sequencia = b.nr_seq_contrato
                                       and    b.cd_estab_adic = cd_estabelecimento_p))
               and rownum = 1
               order by a.nr_sequencia desc;
            exception
               when no_data_found or too_many_rows then
                  vl_unitario_material_w := 0;
            end;
        elsif (nvl(vl_unitario_material_w, 0) = 0) and
               (ie_valor_consignado_w = 'C') then
            begin
               select    nvl(c.vl_saldo_total, c.vl_pagto)
               into      vl_unitario_material_w
               from      contrato            a,
                         contrato_regra_nf   c
               where     a.nr_sequencia = c.nr_seq_contrato
               and       a.cd_cgc_contratado = cd_fornecedor_consignado_p
               and       c.cd_material = cd_material_p
               and       nvl(c.dt_inicio_vigencia, sysdate) <= sysdate
               and       nvl(c.dt_fim_vigencia, sysdate) >= sysdate
               and       nvl(c.ie_situacao, 'A') = 'A'
               and       (c.cd_estab_regra = cd_estabelecimento_p or c.cd_estab_regra is null)
               and       a.dt_inicio <= sysdate
               and       nvl(dt_fim, sysdate) >= sysdate
               and       a.ie_situacao = 'A'
               and       (a.cd_estabelecimento = cd_estabelecimento_p
                            or exists (select 1 from contrato_estab_adic b
                                       where  a.nr_sequencia = b.nr_seq_contrato
                                       and    b.cd_estab_adic = cd_estabelecimento_p))
               and rownum = 1
               order by a.nr_sequencia desc;
            exception
               when no_data_found or too_many_rows then
                  vl_unitario_material_w := 0;
            end;
          end if;
        
		end;
	end loop;
	close C02;

end if;

vl_unitario_material_p := vl_unitario_material_w;

end tcel_obter_vl_mat_ordem_consig;
/