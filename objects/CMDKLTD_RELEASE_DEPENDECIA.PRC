create or replace PROCEDURE CMDKLTD_RELEASE_DEPENDECIA(nr_atendimento_p     	number,
				nm_usuario_p		varchar2) is


BEGIN

update 	atendimento_paciente
set 		dt_fim_conta   	= null,
		ie_fim_conta	= 'A',
		dt_alta_interno	= nvl(dt_alta, pkg_date_utils.get_date(2999, 12, 30, 0)),
		nm_usuario 	= nm_usuario_p
where 	nr_atendimento 	= nr_atendimento_p;

commit;
END CMDKLTD_RELEASE_DEPENDECIA;
/