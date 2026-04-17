# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings related to deprecated APIs or platform compatibility appear in the output.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

---

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only APIs. This is particularly relevant for ADO-related code (e.g., `System.Data.OleDb`, `System.Data.Odbc`), which may require the installation of additional NuGet packages or may not be supported on non-Windows platforms.

Install the compatibility analyzer if not already present:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

---

## 5. Validate NuGet Package References

Open `AdoCore.csproj` and review all `<PackageReference>` entries. Ensure:

- No packages reference .NET Framework-only libraries.
- All packages have versions compatible with your target framework.
- There are no remaining references to `packages.config`-style dependencies.

---

## 6. Verify Runtime Behavior

Run the application against a representative set of inputs or scenarios, particularly around database connectivity, since `AdoCore` implies ADO.NET usage. Confirm that connection strings, provider factories, and data reader behavior function as expected on the target platform.

---

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present. If targeting a specific runtime, add the runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```