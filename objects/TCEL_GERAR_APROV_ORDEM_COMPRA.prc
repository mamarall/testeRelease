create or replace
procedure tcel_gerar_aprov_ordem_compra(
			nr_ordem_compra_p	number,
			cd_perfil_ativo_p		number,
			nm_usuario_p		varchar2) is


cd_estabelecimento_w			number(4);
nr_item_oci_w				number(05,0);
nr_items_sem_aprov_w			number(10);
cd_pessoa_fisica_w			varchar2(10);
cd_cgc_fornecedor_w			varchar2(14);
cd_perfil_w				perfil.cd_perfil%type;
ds_perfil_w				perfil.ds_perfil%type;
dt_ordem_compra_w			date;

cursor c01 is
select	a.nr_item_oci
from	Estrutura_Material_v e, 
	ordem_compra_item a
where	a.nr_ordem_compra		= nr_ordem_compra_p
and	a.cd_material		= e.cd_material
and	a.dt_aprovacao 		is null
and	a.nr_seq_aprovacao	is null
order by	e.cd_grupo_material,
	e.cd_subgrupo_material,
	e.cd_classe_material,
	e.cd_material;

begin

cd_perfil_w			:= cd_perfil_ativo_p;

if	(nvl(cd_perfil_w,0) = 0) then
	select 	obter_perfil_ativo
	into 	cd_perfil_w 
	from 	dual;
	
	if	(cd_perfil_w = 0) then
		cd_perfil_w := null;
	end if;
end if;

if	(nvl(cd_perfil_w,0) > 0) then
	select	max(ds_perfil)
	into	ds_perfil_w
	from	perfil
	where	cd_perfil = cd_perfil_w;
end if;

update	ordem_compra
set	dt_liberacao	= sysdate,
	nm_usuario_lib	= nm_usuario_p
where	nr_ordem_compra	= nr_ordem_compra_p;

inserir_historico_ordem_compra(
	nr_ordem_compra_p,
	'S',		
	WHEB_MENSAGEM_PCK.get_texto(301394),	
	WHEB_MENSAGEM_PCK.get_texto(301393,'CD_PERFIL_W=' || cd_perfil_w || ';' || 'DS_PERFIL_W=' || ds_perfil_w),
	nm_usuario_p);

update	ordem_compra_item
set	qt_original	= qt_material
where	nr_ordem_compra	= nr_ordem_compra_p
and	qt_original is null;

update	ordem_compra_item
set	vl_unit_mat_original = vl_unitario_material
where	nr_ordem_compra	= nr_ordem_compra_p
and	vl_unit_mat_original is null;

select	max(cd_estabelecimento),
	max(cd_cgc_fornecedor),
	max(cd_pessoa_fisica)
into	cd_estabelecimento_w,
	cd_cgc_fornecedor_w,
	cd_pessoa_fisica_w
from	ordem_compra
where	nr_ordem_compra	= nr_ordem_compra_p;

if	(cd_cgc_fornecedor_w is not null) then
	cd_pessoa_fisica_w	:= null;
end if;

calcular_Liquido_ordem_compra(nr_ordem_compra_p, nm_usuario_p);
gerar_conta_financ_oc(nr_ordem_compra_p);

open c01;
loop
fetch c01 into
	nr_item_oci_w;
exit when c01%notfound;
	begin

	update	ordem_compra_item
	set	dt_aprovacao	= sysdate
	where	nr_ordem_compra	= nr_ordem_compra_p
	and	nr_item_oci	= nr_item_oci_w;

	end;
end loop;
close c01;
	
select	count(*)
into	nr_items_sem_aprov_w
from	ordem_compra_item
where	dt_aprovacao is null
and	nr_ordem_compra = nr_ordem_compra_p;

if	(nr_items_sem_aprov_w = 0) then
	
	update	ordem_compra
	set	dt_aprovacao	= sysdate,
		nm_usuario_aprov	= nm_usuario_p
	where	nr_ordem_compra	= nr_ordem_compra_p;
		
end if;

begin
avisar_liberacao_ordem_compra(nr_ordem_compra_p,cd_estabelecimento_w,nm_usuario_p);
exception when others then
	cd_estabelecimento_w	:= cd_estabelecimento_w;
end;

commit;
end tcel_gerar_aprov_ordem_compra;
/
