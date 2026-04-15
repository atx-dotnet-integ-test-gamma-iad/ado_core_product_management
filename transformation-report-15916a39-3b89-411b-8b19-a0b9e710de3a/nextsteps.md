# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that did not surface as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any test failures that may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Review the code for usage of the following, which are common sources of runtime issues after migration:

- `System.Data` and ADO.NET provider registrations (relevant given the `AdoCore` project name)
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- Windows registry access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS restrictions)

## 5. Validate ADO.NET Database Connectivity

Since the project is named `AdoCore`, confirm that your database driver NuGet packages are explicitly referenced in the `.csproj` file, as automatic provider registration from `machine.config` is not available in .NET Core and later:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

Also verify that any provider factory registrations previously handled via `app.config` or `machine.config` are now done in code or via the appropriate package's built-in registration mechanism.

## 6. Review Configuration Files

`app.config` is not used the same way in modern .NET. If the project relied on `app.config` for connection strings or application settings, migrate these to `appsettings.json` and use `Microsoft.Extensions.Configuration`:

```bash
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
```

## 7. Run on Target Operating Systems

If cross-platform support is a goal, test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.