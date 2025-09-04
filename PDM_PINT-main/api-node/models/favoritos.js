const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('favoritos', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    id_utilizador: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'utilizador',
        key: 'idutilizador'
      }
    },
    id_curso: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'cursos',
        key: 'id'
      }
    },
    data_adicionado: {
      type: DataTypes.DATE,
      allowNull: true,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    }
  }, {
    sequelize,
    tableName: 'favoritos',
    schema: 'public',
    timestamps: false,
    indexes: [
      {
        name: "favoritos_pk",
        unique: true,
        fields: [
          { name: "id" },
        ]
      },
      {
        name: "favoritos_idx",
        fields: [
          { name: "id_utilizador" },
          { name: "id_curso" },
        ]
      },
      {
        name: "favoritos_unique",
        unique: true,
        fields: [
          { name: "id_utilizador" },
          { name: "id_curso" },
        ]
      }
    ]
  });
};
