create or replace PROCEDURE  CMDKLTD_RELEASE_TESTE_HASH AS
    v_observacao DIC_EXPRESSAO.DS_REVISAO%TYPE;
	v_descricao varchar2(4000);
BEGIN
   SELECT DS_REVISAO, 
   obter_desc_expressao(cd_expressao, ds_expressao_br)
    INTO v_observacao, v_descricao
    FROM DIC_EXPRESSAO
    where ROWNUM = 1;

    INSERT INTO CMDKLTD_CUSTOM_REFACTORED (
        NR_SEQUENCIA, DS_NAME
    ) VALUES (
        2,
        v_observacao 
    );
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao cadastrar na CMDKLTD_CUSTOM: ' || SQLERRM);
END CMDKLTD_RELEASE_TESTE_HASH;
/