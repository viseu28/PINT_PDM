var DataTypes = require("sequelize").DataTypes;
var _administra = require("./administra");
var _administrador = require("./administrador");
var _analisa = require("./analisa");
var _areas = require("./areas");
var _assincrono = require("./assincrono");
var _avaliacoes = require("./avaliacoes");
var _categorias = require("./categorias");
var _comentarios = require("./comentarios");
var _conteudo = require("./conteudo");
var _curriculopendente = require("./curriculopendente");
var _cursos = require("./cursos");
var _cursospendentes = require("./cursospendentes");
var _denuncia = require("./denuncia");
var _disponibiliza = require("./disponibiliza");
var _favoritos = require("./favoritos");
var _formCurriculo = require("./formCurriculo");
var _formInscricao = require("./formInscricao");
var _formador = require("./formador");
var _formando = require("./formando");
var _forum = require("./forum");
var _gerirConteudo = require("./gerirConteudo");
var _gerirCurso = require("./gerirCurso");
var _horariopessoal = require("./horariopessoal");
var _horariosemanal = require("./horariosemanal");
var _inscricaoCurso = require("./inscricaoCurso");
var _material = require("./material");
var _notificacao = require("./notificacao");
var _percursoformativo = require("./percursoformativo");
var _post = require("./post");
var _projetos = require("./projeto");
var _projetos_submissoes = require("./projetos_submissoes");
var _recebe = require("./recebe");
var _sincronos = require("./sincronos");
var _temConteudo = require("./temConteudo");
var _topicos = require("./topicos");
var _utilizador = require("./utilizador");
var _resposta = require("./resposta");
var _guardado = require("./guardados");
var _likes_forum = require("./likes_forum");
var _denuncia = require("./denuncia");
var _permissoes = require("./permissoes");
var _roles_permissoes = require("./roles_permissoes");

function initModels(sequelize) {
  const models = {
    administra: _administra(sequelize, DataTypes),
    administrador: _administrador(sequelize, DataTypes),
    analisa: _analisa(sequelize, DataTypes),
    areas: _areas(sequelize, DataTypes),
    assincrono: _assincrono(sequelize, DataTypes),
    avaliacoes: _avaliacoes(sequelize, DataTypes),
    categorias: _categorias(sequelize, DataTypes),
    conteudo: _conteudo(sequelize, DataTypes),
    curriculopendente: _curriculopendente(sequelize, DataTypes),
    cursos: _cursos(sequelize, DataTypes),
    cursospendentes: _cursospendentes(sequelize, DataTypes),
    denuncia: _denuncia(sequelize, DataTypes),
    disponibiliza: _disponibiliza(sequelize, DataTypes),
    favoritos: _favoritos(sequelize, DataTypes),
    formCurriculo: _formCurriculo(sequelize, DataTypes),  
    formInscricao: _formInscricao(sequelize, DataTypes),
    formador: _formador(sequelize, DataTypes),
    formando: _formando(sequelize, DataTypes),
    forum: _forum(sequelize, DataTypes),
    gerirConteudo: _gerirConteudo(sequelize, DataTypes),
    gerirCurso: _gerirCurso(sequelize, DataTypes),
    horariopessoal: _horariopessoal(sequelize, DataTypes),
    horariosemanal: _horariosemanal(sequelize, DataTypes),
    inscricaoCurso: _inscricaoCurso(sequelize, DataTypes),
    material: _material(sequelize, DataTypes),
    notificacao: _notificacao(sequelize, DataTypes),
    percursoformativo: _percursoformativo(sequelize, DataTypes),
    post: _post(sequelize, DataTypes),
    projetos: _projetos(sequelize, DataTypes),
    projetos_submissoes: _projetos_submissoes(sequelize, DataTypes),
    recebe: _recebe(sequelize, DataTypes),
    sincronos: _sincronos(sequelize, DataTypes),
    temConteudo: _temConteudo(sequelize, DataTypes),
    topicos: _topicos(sequelize, DataTypes),
    utilizador: _utilizador(sequelize, DataTypes),
    resposta: _resposta(sequelize, DataTypes),
    guardado: _guardado(sequelize, DataTypes),
    likes_forum: _likes_forum(sequelize, DataTypes),
    denuncia: _denuncia(sequelize, DataTypes),
    comentarios: _comentarios(sequelize, DataTypes),
    permissoes: _permissoes(sequelize, DataTypes),
    roles_permissoes: _roles_permissoes(sequelize, DataTypes),
  };

  // --- ASSOCIAÇÕES FÓRUM ---
  models.categorias.hasMany(models.areas, { foreignKey: 'idcategoria', as: 'areas' });
  models.areas.belongsTo(models.categorias, { foreignKey: 'idcategoria', as: 'categoria' });

  models.areas.hasMany(models.topicos, { foreignKey: 'idarea', as: 'topicos' });
  models.topicos.belongsTo(models.areas, { foreignKey: 'idarea', as: 'area' });

  models.favoritos.belongsTo(models.cursos, { foreignKey: 'id_curso', as: 'curso' });

  models.projetos.hasMany(models.projetos_submissoes, {
  foreignKey: 'id_projeto',
  as: 'submissoes'
});
models.projetos_submissoes.belongsTo(models.projetos, {
  foreignKey: 'id_projeto',
  as: 'projeto'
});




  // --- RESTO DO TEU CÓDIGO ---
  Object.values(models).forEach((model) => {
    if (model.associate) model.associate(models);
  });

  return models;
}

module.exports = initModels;
module.exports.initModels = initModels;
module.exports.default = initModels;
