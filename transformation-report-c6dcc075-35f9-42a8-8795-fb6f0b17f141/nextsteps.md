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

Verify that no warnings are being treated as errors and that all output assemblies are produced in the expected `bin/Release` directories.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime (e.g., differences in globalization, reflection, or threading behavior).

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas during runtime validation:

- **Database connectivity**: ADO.NET connection strings and driver packages (e.g., `Microsoft.Data.SqlClient`) may need to be updated if the project uses data access.
- **Configuration**: `System.Configuration.ConfigurationManager` behavior may differ. Ensure `app.config` or `appsettings.json` is being read correctly.
- **Platform-specific APIs**: Any calls to Windows-only APIs (e.g., registry access, COM interop) will fail on non-Windows platforms. Use `RuntimeInformation.IsOSPlatform` guards if cross-platform support is required.
- **Reflection and serialization**: Behavior of `Type.GetType`, `Assembly.Load`, and binary serialization may differ from .NET Framework.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their .NET-compatible equivalents where available.

## 6. Validate Output and Artifacts

After a successful Release build, confirm the output directory contains the expected:

- `.dll` or `.exe` assemblies
- `.deps.json` and `.runtimeconfig.json` files (for executable projects)
- Any required static assets or configuration files

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Smoke Test the Published Output

Navigate to the `./publish` directory and run the application directly to confirm it starts and behaves correctly in the published form, independent of the SDK installation.