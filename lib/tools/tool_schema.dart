class Parameter {
  final String type;
  final String description;
  final bool required;
  final List<String>? enumValues;

  const Parameter.string({
    required this.description,
    this.required = false,
    this.enumValues,
  }) : type = 'string';

  const Parameter.integer({
    required this.description,
    this.required = false,
    this.enumValues,
  }) : type = 'integer';

  const Parameter.boolean({
    required this.description,
    this.required = false,
    this.enumValues,
  }) : type = 'boolean';

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'type': type,
      'description': description,
    };
    if (enumValues != null) {
      json['enum'] = enumValues;
    }
    return json;
  }
}

class ToolParameters {
  final Map<String, Parameter> properties;

  const ToolParameters(this.properties);

  Map<String, Object?> toJson() => {
    'type': 'object',
    'properties': properties.map((key, value) => MapEntry(key, value.toJson())),
    'required': properties.entries.where((entry) => entry.value.required).map((entry) => entry.key).toList(),
  };
}
