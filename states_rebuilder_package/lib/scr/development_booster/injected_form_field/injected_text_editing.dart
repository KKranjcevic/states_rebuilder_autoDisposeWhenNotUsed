import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../state_management/listeners/on_reactive.dart';
import '../../state_management/rm.dart';

part 'i_base_form_field.dart';
part 'injected_form.dart';
part 'injected_form_field.dart';
part 'on_form_builder.dart';
part 'on_form_field_builder.dart';
part 'on_form_submission_builder.dart';

///{@template InjectedTextEditing}
///Inject a [TextEditingController]
///
/// This injected state abstracts the best practices to come out with a
/// simple, clean, and testable approach deal with TextField and form
/// validation.
///
/// The approach consists of the following steps:
///   ```dart
///      final email =  RM.injectTextEditing():
///   ```
/// * Instantiate an [InjectedTextEditing] object using [RM.injectTextEditing]
/// * Link the injected state to a [TextField] (No need to [TextFormField] even
/// inside a [OnFormBuilder]).
///   ```dart
///      TextField(
///         controller: email.controller,
///         focusNode: email.focusNode, //It is auto disposed of.
///         decoration:  InputDecoration(
///             errorText: email.error, //To display the error message.
///         ),
///         onSubmitted: (_) {
///             //Focus on the password TextField after submission
///             password.focusNode.requestFocus();
///         },
///     ),
///   ```
///
/// See also :
/// * [InjectedFormField] for other type of inputs rather the text,
/// * [InjectedForm] and [OnFormBuilder] to work with form.
///  {@endtemplate}
abstract mixin class InjectedTextEditing implements IObservable<String> {
  late TextEditingControllerImp? _controller;

  late final _baseFormField = this as _BaseFormField;

  ///A controller for an editable text field.
  TextEditingControllerImp get controller;

  /// Initializes a controller with the given initial text.
  ///
  /// It is useful when the initial value is obtained in the build method of
  /// the widget tree. (We can not initialize the controller when creating the
  /// injectedTextEditingController)
  ///
  /// **Don't do**
  /// ```dart
  /// final myInjectedController= RM.injectTextEditingController();
  ///
  /// // In the widget tree
  /// Widget builder(BuildContext context){
  ///   final initialValue = ...;
  ///    return TextField(
  ///      controller: myInjectedController.controller..text = initialValue,
  ///    )
  /// }
  /// ```
  ///
  /// **Do**
  /// ```dart
  /// final myInjectedController= RM.injectTextEditingController();
  ///
  /// // In the widget tree
  /// Widget builder(BuildContext context){
  ///   final initialValue = ...;
  ///    return TextField(
  ///      controller: myInjectedController.controllerWithInitialText(initialValue) ,
  ///    )
  /// }
  /// ```
  TextEditingControllerImp controllerWithInitialText(String text);

  ///The current text being edited.
  String get text => snapState.state;

  ///Whether it passes the validation test
  bool get isValid;

  /// Whether the the value of the field is modified and not submitted yet;
  ///
  /// Submission is done using [InjectedForm.submit] method.
  bool get isDirty;

  /// Get the text of the field
  String get value => text;

  @Deprecated('use value instead')
  String get state => value;

  ///The range of text that is currently selected.
  TextSelection get selection => _controller!.value.selection;

  ///The range of text that is still being composed.
  TextRange get composing => _controller!.value.composing;

  /// set the error
  set error(dynamic error);

  /// reset the text of the field
  void reset() {
    _controller?.text = _baseFormField.initialValue;
    _baseFormField.resetField();
  }

  ///Creates a focus node for this TextField
  FocusNode get focusNode {
    ReactiveStatelessWidget.addToObs?.call(this as ReactiveModelImp);
    _baseFormField._focusNode ??= FocusNode();
    return _baseFormField.__focusNode;
  }

  /// Invoke field validators and return true if the field is valid.
  bool validate();

  /// If true the [TextField] is clickable, selectable and focusable but not
  /// editable.
  ///
  /// For it to work you must set readOnly property of [TextField.readOnly] to :
  ///
  /// ```dart
  ///   final myText = RM.injectedTextEditing();
  ///   TextField(
  ///     readOnly: myText.isReadOnly,
  ///   )
  /// ```
  ///
  bool isReadOnly = false;

  /// If false the associated [TextField] is disabled.
  ///
  /// For it to work you must set `enabled` property of [TextField.enabled] to:
  ///
  /// ```dart
  ///   final myText = RM.injectedTextEditing();
  ///   TextField(
  ///     enabled: myText.isEnabled,
  ///   )
  /// ```
  bool isEnabled = true;
}

/// InjectedTextEditing implementation
class InjectedTextEditingImp extends ReactiveModelImp<String>
    with InjectedTextEditing, _BaseFormField<String> {
  InjectedTextEditingImp({
    String text = '',
    TextSelection selection = const TextSelection.collapsed(offset: -1),
    TextRange composing = TextRange.empty,
    List<String? Function(String?)>? validator,
    bool? validateOnTyping,
    this.autoDispose = true,
    this.onTextEditing,
    bool? validateOnLoseFocus,
    bool? isReadOnly,
    bool? isEnabled,
  })  : _composing = composing,
        _selection = selection,
        super(
          creator: () => text,
          initialState: text,
          autoDisposeWhenNotUsed: autoDispose,
          stateInterceptorGlobal: null,
        ) {
    _resetDefaultState = () {
      initialValue = text;
      _controller = null;
      form = null;
      _formIsSet = false;
      _removeFromInjectedList = null;
      formTextFieldDisposer = null;
      _validateOnLoseFocus = validateOnLoseFocus;
      _isValidOnLoseFocusDefined = false;
      _validator = validator;
      _validateOnValueChange = validateOnTyping;
      _focusNode = null;
      _isReadOnly = _initialIsReadOnly = isReadOnly;
      _isEnabled = _initialIsEnabled = isEnabled;
      isDirty = false;
      _initialIsDirtyText = text;
    };
    _resetDefaultState();
  }

  @override
  final bool autoDispose;
  final void Function(InjectedTextEditing textEditing)? onTextEditing;

  final TextSelection _selection;
  final TextRange _composing;

  late bool _formIsSet;
  late VoidCallback? _removeFromInjectedList;

  ///Remove this InjectedTextEditing from the associated InjectedForm,
  late VoidCallback? formTextFieldDisposer;
  late bool? _initialIsEnabled;
  late bool? _initialIsReadOnly;

  //
  late final VoidCallback _resetDefaultState;

  @override
  TextEditingControllerImp controllerWithInitialText(String text) {
    if (_controller == null) {
      return controller..text = text;
    }
    return controller;
  }

  @override
  TextEditingControllerImp get controller {
    if (!_formIsSet) {
      form ??= InjectedFormImp._currentInitializedForm;
      _formIsSet = true; // TODO check me
      if (form != null) {
        formTextFieldDisposer =
            (form as InjectedFormImp).addTextFieldToForm(this);

        if (form!.autovalidateMode == AutovalidateMode.always) {
          //When initialized and always auto validated, then validate in the next
          //frame
          WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
              form!.validate();
            },
          );
        } else {
          if (_validateOnLoseFocus == null && _validateOnValueChange != true) {
            //If the TextField is inside a On.form, set _validateOnLoseFocus to
            //true if it is not
            _validateOnLoseFocus = true;
            if (!_isValidOnLoseFocusDefined) {
              _listenToFocusNodeForValidation();
            }
          }
        }
      }
    }

    if (_controller != null) {
      value; // fix issue 241
      return _controller!;
    }
    // _removeFromInjectedList = addToInjectedModels(this);

    _controller ??= TextEditingControllerImp.fromValue(
      TextEditingValue(
        text: initialValue ?? '',
        selection: _selection,
        composing: _composing,
      ),
      inj: this,
    );
    if (_validator == null) {
      //If the field is not validate then set its snapshot to hasData, so that
      //in the [InjectedForm.isValid] consider it as a valid field
      snapValue = snapValue.copyToHasData(text);
    }

    // else {
    //   //IF there is a validator, then set with idle flag so that isValid
    //   //is false unless validator is called
    //   snapState = snapState.copyToIsIdle(this.text);
    // }
    _controller!.addListener(() {
      if (isReadOnly) {
        if (_controller!.text != snapValue.state) {
          _controller!.text = snapValue.state;
        }
        return;
      }
      onTextEditing?.call(this);
      if (snapValue.state == _controller!.text) {
        //if only selection is changed notify and return
        notify();
        return;
      }
      isDirty = _controller!.text.trim() != _initialIsDirtyText.trim();
      snapValue = snapValue.copyWith(data: _controller!.text);
      if (form != null) {
        //If form is not null than override the autoValidate of this Injected
        _validateOnValueChange ??=
            form!.autovalidateMode != AutovalidateMode.disabled;
      }
      if (_validateOnValueChange ?? !(_validateOnLoseFocus ?? false)) {
        validate();
      }
      notify();
    });

    return _controller!;
  }

  @override
  bool get isEnabled {
    ReactiveStatelessWidget.addToObs?.call(this);

    controller;
    if (_isEnabled != null) {
      return _isEnabled!;
    }
    final isFormEnabled = (form as InjectedFormImp?)?._isEnabled;
    if (isFormEnabled != null) {
      return isFormEnabled;
    }

    return true;
  }

  @override
  set isEnabled(bool? val) {
    _isEnabled = val;
    notify();
  }

  @override
  bool get isReadOnly {
    ReactiveStatelessWidget.addToObs?.call(this);
    controller;
    if (_isReadOnly != null) {
      return _isReadOnly!;
    }
    final isFormReadOnly = (form as InjectedFormImp?)?._isReadOnly;
    if (isFormReadOnly != null) {
      return isFormReadOnly;
    }
    return false;
  }

  @override
  set isReadOnly(bool? val) {
    _isReadOnly = val;
    notify();
  }

  @override
  void reset() {
    _isEnabled = _initialIsEnabled;
    _isReadOnly = _initialIsReadOnly;
    super.reset();
  }

  @override
  void dispose() {
    super.dispose();
    _removeFromInjectedList?.call();
    _controller?.dispose();
    _controller = null;
    formTextFieldDisposer?.call();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      //Dispose after the associated TextField remove its listeners to _focusNode
      _focusNode?.dispose();
      _resetDefaultState();
    });
  }
}

///Custom extension of [TextEditingController]
///
///Used to dispose the associated [InjectedEditingText] if the associated
///Text field is removed from the widget tree.
class TextEditingControllerImp extends TextEditingController {
  TextEditingControllerImp.fromValue(
    TextEditingValue? value, {
    required this.inj,
  }) : super.fromValue(value);
  int _numberOfAddListener = 0;
  final InjectedTextEditingImp inj;
  @override
  void addListener(listener) {
    _numberOfAddListener++;
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    if (inj._controller == null) {
      return;
    }
    _numberOfAddListener--;
    if (_numberOfAddListener < 3) {
      if (inj.autoDispose) {
        inj.dispose();
        return;
      }
    }

    super.removeListener(listener);
  }
}
