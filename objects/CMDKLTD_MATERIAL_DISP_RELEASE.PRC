create or replace procedure CMDKLTD_MATERIAL_DISP_RELEASE(NR_SEQUENCIA_P NUMBER) is

SUP_MATERIAL_DISP_MERCADO_w	SUP_MATERIAL_DISP_MERCADO%rowtype;
CMDKLTD_MATMARC_w	CMDKLTD_MATMARC%rowtype;

cursor c01 is
select	*
from	material_marca
where	cd_material = SUP_MATERIAL_DISP_MERCADO_w.cd_material;

c01_w	c01%rowtype;

begin

begin
select	*
into	SUP_MATERIAL_DISP_MERCADO_w
from	SUP_MATERIAL_DISP_MERCADO
where	NR_SEQUENCIA = NR_SEQUENCIA_P;
exception
when others then
	SUP_MATERIAL_DISP_MERCADO_w	:=	null;
end;

open c01;
	loop
	fetch c01 into
		c01_w;
	exit when c01%notfound;
		begin
		update	CMDKLTD_MATMARC
		set	ie_disponivel_mercado = SUP_MATERIAL_DISP_MERCADO_w.ie_disponivel_mercado
		where	nr_sequencia = c01_w.NR_SEQUENCIA
		and	cd_material = c01_w.cd_material;
		
		if	(sql%notfound) then
			begin
			CMDKLTD_MATMARC_w	:=	null;
			CMDKLTD_MATMARC_w.nr_sequencia	:=	c01_w.NR_SEQUENCIA;
			CMDKLTD_MATMARC_w.cd_material	:=	c01_w.cd_material;
			CMDKLTD_MATMARC_w.ie_disponivel_mercado	:=	SUP_MATERIAL_DISP_MERCADO_w.ie_disponivel_mercado;
			
			insert into CMDKLTD_MATMARC values CMDKLTD_MATMARC_w;
			end;		
		end if;
		
		update material_marca
		set	ds_observacao = SUP_MATERIAL_DISP_MERCADO_w.DS_OBS_DISP_MERCADO
		where	cd_material = SUP_MATERIAL_DISP_MERCADO_w.cd_material;
		end;
	end loop;
close c01; 


end CMDKLTD_MATERIAL_DISP_RELEASE;
/