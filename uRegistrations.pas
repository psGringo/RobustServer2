unit uRegistrations;

interface

uses
  Spring.Container;

procedure RegisterTypes(const container: TContainer);

implementation

procedure RegisterTypes(const container: TContainer);
begin
//  container.RegisterType<TOrderEntry>;
//  container.RegisterType<TOrderValidator>;

  container.Build;
end;

end.

