# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding further.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently across .NET versions. Review the following areas manually:

- **Database/ADO.NET usage**: Since the project is named `AdoCore`, verify that any `System.Data` or provider-specific (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) calls function correctly at runtime.
- **Configuration**: Ensure `App.config` or `Web.config` based configuration has been migrated to `appsettings.json` or environment variables if applicable.
- **Platform-specific APIs**: Check for any calls to Windows-only APIs if cross-platform support is required.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm each package targets .NET Standard 2.0+ or the specific .NET version you are using. You can check compatibility at [nuget.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases compatible with your target framework.

## 6. Validate Runtime Behavior

Run the application manually or through integration tests and exercise the primary workflows, particularly any ADO.NET database interactions. Check for:

- Connection string formats that may differ between .NET Framework and modern .NET.
- Any `DbProviderFactories` registrations that must now be done explicitly in modern .NET.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If targeting a specific runtime, add the `-r` flag:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained false --output ./publish
```

Adjust the runtime identifier (`win-x64`, `linux-x64`, etc.) based on your deployment target.