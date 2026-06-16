# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may not be supported cross-platform:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`System.Runtime.InteropServices`)

## 5. Validate ADO.NET / Database Connectivity

Since this project appears to be ADO.NET-related, verify that the database drivers in use are available as cross-platform NuGet packages. For example:

| Legacy Driver | Cross-Platform Replacement |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| OLE DB providers | Not supported on non-Windows; use a native driver |
| ODBC | Available on Linux/macOS but requires native drivers installed |

Update connection string handling and provider factory usage if the driver was changed.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application or tests on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that only target `net45` or similar may still resolve but could produce runtime failures:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to versions with cross-platform support.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the target machine.